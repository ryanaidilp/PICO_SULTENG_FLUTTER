// `onRedaction` is derived from `logRedactions` below, which requires an
// explicit super-initializer, and Dart forbids combining one with super
// parameters. The lint's suggestion is not expressible here.
// ignore_for_file: use_super_parameters

import 'package:consent_api/consent_api.dart';
import 'package:flutter/foundation.dart';

/// The app's default [TelemetryScrubber]: the shared rule engine wired to the
/// default rule set, plus debug-build redaction logging.
///
/// The logging is the answer to the false-positive risk. Value-shape detection
/// *will* redact something it should not have — a support-ticket ID that is a
/// long digit run is the canonical case. Rather than weakening the rules
/// pre-emptively, every redaction is printed in debug builds with its key and
/// reason (never its value), so a team can see what is actually being redacted
/// and tune [ScrubRules] against evidence.
class DefaultTelemetryScrubber({
  ScrubRules rules = const ScrubRules(),
  bool? logRedactions,
}) extends RuleBasedTelemetryScrubber {
  /// Creates the default scrubber.
  ///
  /// Pass [rules] to tune the policy per app; pass [logRedactions] to force
  /// logging on or off instead of following [kDebugMode].
  this
    : super(
        rules: rules,
        onRedaction: (logRedactions ?? kDebugMode) ? _log : null,
      );

  static void _log(RedactionRecord record) {
    debugPrint(
      '[scrubber] redacted ${record.channel}:${record.path ?? record.key} '
      '(${record.reason.wireName})',
    );
  }
}
