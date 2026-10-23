import 'package:dependencies_core/meta.dart';

/// Why a value was redacted.
enum RedactionReason(
  /// Stable name for logs and metrics.
  final String wireName,
) {
  /// The key matched a deny-list fragment.
  deniedKey('denied_key'),

  /// Default-deny mode is on and the key is not on the allow-list.
  notAllowListed('not_allow_listed'),

  /// The value is shaped like an email address.
  emailValue('email_value'),

  /// The value contains a long run of digits.
  digitRun('digit_run'),

  /// The value is shaped like a credential.
  bearerToken('bearer_token'),

  /// The payload exceeded the scan budget; the remainder failed closed.
  budgetExceeded('budget_exceeded'),

  /// The value nested deeper than the configured maximum.
  depthExceeded('depth_exceeded'),
}

/// An observable record that one value was redacted.
///
/// Deliberately carries the key and the reason but **never the value** — a
/// redaction log that contains the redacted data is not a redaction log.
@immutable
class const RedactionRecord({
  /// The property key whose value was redacted.
  required final String key,

  /// Why it was redacted.
  required final RedactionReason reason,

  /// Which telemetry surface produced it (`analytics`, `monitoring`, ...).
  final String channel = 'unknown',

  /// Dotted path to the value inside a nested payload, when applicable.
  final String? path,
}) {
  /// Creates a redaction record.
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedactionRecord &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          reason == other.reason &&
          channel == other.channel &&
          path == other.path;

  @override
  int get hashCode => Object.hash(key, reason, channel, path);

  @override
  String toString() =>
      'RedactionRecord($channel:${path ?? key} -> ${reason.wireName})';
}
