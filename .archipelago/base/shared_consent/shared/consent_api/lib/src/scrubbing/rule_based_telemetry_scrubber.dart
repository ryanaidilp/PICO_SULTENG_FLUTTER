import 'dart:async';

import 'package:consent_api/src/scrubbing/redaction_record.dart';
import 'package:consent_api/src/scrubbing/scrub_result.dart';
import 'package:consent_api/src/scrubbing/scrub_rules.dart';
import 'package:consent_api/src/scrubbing/telemetry_key_normalizer.dart';
import 'package:consent_api/src/scrubbing/telemetry_scrubber.dart';
import 'package:consent_api/src/scrubbing/telemetry_value_shapes.dart';

/// Reference [TelemetryScrubber] driven by a [ScrubRules] policy.
///
/// Lives in `consent_api` rather than `consent_impl` because it is a pure,
/// dependency-free engine over the declarative rule model — putting it here
/// lets every consumer construct one without pulling in a Flutter-bound impl
/// package. `consent_impl` owns the *wiring*: the default rule set, DI
/// registration, persistence and debug-build redaction logging.
///
/// ## Cost
///
/// Detection is regex-free (see `TelemetryValueShapes`) and every traversal is
/// bounded by [ScrubRules.maxScannedEntries], [ScrubRules.maxScannedCharacters]
/// and [ScrubRules.maxDepth]. Worst case per payload is therefore linear in
/// the scan budget with no backtracking, which is what makes this safe to run
/// on every event.
class RuleBasedTelemetryScrubber({
  @override final ScrubRules rules = const ScrubRules(),

  /// Called synchronously for every redaction, before the stream is notified.
  ///
  /// Used by `DefaultTelemetryScrubber` to log redactions in debug builds.
  final void Function(RedactionRecord record)? onRedaction,
}) implements TelemetryScrubber {
  /// Creates a scrubber enforcing [rules].
  this;

  /// Largest number of distinct keys whose deny/allow verdict is memoised.
  ///
  /// Keys repeat heavily across events, so a small cache removes almost all
  /// normalisation work from the hot path. Bounded so an app that generates
  /// unique keys per event cannot grow it without limit.
  static const int maxKeyCacheSize = 512;

  final Map<String, RedactionReason?> _keyVerdictCache = {};
  final StreamController<RedactionRecord> _redactions =
      StreamController<RedactionRecord>.broadcast();

  int _redactionCount = 0;

  @override
  int get redactionCount => _redactionCount;

  @override
  Stream<RedactionRecord> get redactions => _redactions.stream;

  @override
  void resetRedactionCount() {
    _redactionCount = 0;
  }

  /// Closes the redaction stream. Call on app teardown.
  Future<void> dispose() => _redactions.close();

  @override
  ScrubResult scrubProperties(
    Map<String, dynamic> properties, {
    String channel = 'unknown',
  }) {
    if (properties.isEmpty) return const ScrubResult.clean({});

    final budget = _ScanBudget(rules.maxScannedCharacters);
    final records = <RedactionRecord>[];
    final scrubbed = _scrubMap(
      properties,
      channel: channel,
      pathPrefix: null,
      depth: 0,
      budget: budget,
      records: records,
    );

    records.forEach(_publish);
    return ScrubResult(values: scrubbed, redactions: records);
  }

  @override
  ScrubbedText scrubText(
    String text, {
    String channel = 'unknown',
    String key = 'message',
  }) {
    if (text.isEmpty) return const ScrubbedText.clean('');

    // Free text is redacted span-by-span rather than wholesale: replacing an
    // entire log line because one token was an email destroys the diagnostic
    // value the line existed for.
    final buffer = StringBuffer();
    final records = <RedactionRecord>[];
    var start = 0;
    var index = 0;

    void handleSpan(int end) {
      if (end <= start) return;
      final span = text.substring(start, end);
      final reason = _valueReason(span);
      if (reason == null) {
        buffer.write(span);
      } else {
        buffer.write(rules.redactionMarker);
        records.add(
          RedactionRecord(key: key, reason: reason, channel: channel),
        );
      }
    }

    while (index < text.length) {
      if (_isWhitespace(text.codeUnitAt(index))) {
        handleSpan(index);
        buffer.write(text[index]);
        start = index + 1;
      }
      index++;
    }
    handleSpan(text.length);

    if (records.isEmpty) return ScrubbedText.clean(text);
    records.forEach(_publish);
    return ScrubbedText(text: buffer.toString(), redactions: records);
  }

  // ---------------------------------------------------------------------------
  // Traversal
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _scrubMap(
    Map<String, dynamic> source, {
    required String channel,
    required String? pathPrefix,
    required int depth,
    required _ScanBudget budget,
    required List<RedactionRecord> records,
  }) {
    final result = <String, dynamic>{};
    var examined = 0;

    for (final entry in source.entries) {
      final path = pathPrefix == null ? entry.key : '$pathPrefix.${entry.key}';

      if (examined >= rules.maxScannedEntries || budget.isExhausted) {
        result[entry.key] = rules.redactionMarker;
        records.add(
          RedactionRecord(
            key: entry.key,
            reason: RedactionReason.budgetExceeded,
            channel: channel,
            path: path,
          ),
        );
        continue;
      }
      examined++;

      final keyReason = _keyReason(entry.key);
      if (keyReason != null) {
        result[entry.key] = rules.redactionMarker;
        records.add(
          RedactionRecord(
            key: entry.key,
            reason: keyReason,
            channel: channel,
            path: path,
          ),
        );
        continue;
      }

      result[entry.key] = _scrubValue(
        entry.key,
        entry.value,
        channel: channel,
        path: path,
        depth: depth,
        budget: budget,
        records: records,
      );
    }
    return result;
  }

  Object? _scrubValue(
    String key,
    Object? value, {
    required String channel,
    required String path,
    required int depth,
    required _ScanBudget budget,
    required List<RedactionRecord> records,
  }) {
    if (value == null) return null;

    if (value is String) {
      budget.consume(value.length);
      final reason = _valueReason(value);
      if (reason == null) return value;
      records.add(
        RedactionRecord(key: key, reason: reason, channel: channel, path: path),
      );
      return rules.redactionMarker;
    }

    // Numbers and booleans carry no detectable shape. Digit-run detection is
    // deliberately not applied to them: a millisecond epoch is 13 digits and
    // would be redacted from every event that carries a timestamp.
    if (value is num || value is bool) return value;

    if (depth >= rules.maxDepth) {
      records.add(
        RedactionRecord(
          key: key,
          reason: RedactionReason.depthExceeded,
          channel: channel,
          path: path,
        ),
      );
      return rules.redactionMarker;
    }

    if (value is Map) {
      return _scrubMap(
        value.map((k, v) => MapEntry('$k', v)),
        channel: channel,
        pathPrefix: path,
        depth: depth + 1,
        budget: budget,
        records: records,
      );
    }

    if (value is Iterable) {
      return [
        for (final element in value)
          _scrubValue(
            key,
            element,
            channel: channel,
            path: path,
            depth: depth + 1,
            budget: budget,
            records: records,
          ),
      ];
    }

    // Unknown object: its toString() is what a vendor SDK would serialise, so
    // that is what gets inspected.
    final rendered = value.toString();
    budget.consume(rendered.length);
    final reason = _valueReason(rendered);
    if (reason == null) return value;
    records.add(
      RedactionRecord(key: key, reason: reason, channel: channel, path: path),
    );
    return rules.redactionMarker;
  }

  // ---------------------------------------------------------------------------
  // Rules
  // ---------------------------------------------------------------------------

  /// Returns why [key] is denied, or `null` when the key itself is fine.
  RedactionReason? _keyReason(String key) {
    final cached = _keyVerdictCache[key];
    if (cached != null || _keyVerdictCache.containsKey(key)) return cached;

    final normalized = TelemetryKeyNormalizer.normalize(key);
    RedactionReason? reason;

    final allowed = rules.allowedKeys;
    if (allowed != null &&
        !allowed.contains(key) &&
        !allowed.contains(normalized.flattened)) {
      reason = RedactionReason.notAllowListed;
    } else {
      for (final token in normalized.tokens) {
        if (rules.deniedKeyTokens.contains(token)) {
          reason = RedactionReason.deniedKey;
          break;
        }
      }
      if (reason == null) {
        for (final fragment in rules.deniedKeySubstrings) {
          if (normalized.flattened.contains(fragment)) {
            reason = RedactionReason.deniedKey;
            break;
          }
        }
      }
    }

    if (_keyVerdictCache.length >= maxKeyCacheSize) _keyVerdictCache.clear();
    _keyVerdictCache[key] = reason;
    return reason;
  }

  /// Returns why [value] is denied by shape, or `null` when it looks safe.
  RedactionReason? _valueReason(String value) {
    if (value.isEmpty) return null;
    if (rules.detectEmailValues && TelemetryValueShapes.looksLikeEmail(value)) {
      return RedactionReason.emailValue;
    }
    if (rules.detectBearerTokens &&
        TelemetryValueShapes.looksLikeBearerToken(value)) {
      return RedactionReason.bearerToken;
    }
    if (rules.detectDigitRuns &&
        TelemetryValueShapes.hasLongDigitRun(value, rules.digitRunThreshold)) {
      return RedactionReason.digitRun;
    }
    return null;
  }

  void _publish(RedactionRecord record) {
    _redactionCount++;
    onRedaction?.call(record);
    if (_redactions.hasListener) _redactions.add(record);
  }

  static bool _isWhitespace(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;
}

/// Mutable character budget shared across one payload traversal.
class _ScanBudget(var int _remaining) {
  bool get isExhausted => _remaining <= 0;

  void consume(int characters) {
    _remaining -= characters;
  }
}
