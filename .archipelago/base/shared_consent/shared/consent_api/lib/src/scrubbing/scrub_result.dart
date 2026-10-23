import 'package:consent_api/src/scrubbing/redaction_record.dart';
import 'package:dependencies_core/meta.dart';

/// The outcome of scrubbing a payload.
@immutable
class ScrubResult {
  /// Creates a result.
  const new({required this.values, required this.redactions});

  /// A result with nothing redacted.
  const new clean(this.values) : redactions = const [];

  /// The scrubbed payload. Redacted entries hold the rule set's marker.
  final Map<String, dynamic> values;

  /// One record per redacted value.
  final List<RedactionRecord> redactions;

  /// Whether anything was redacted.
  bool get hasRedactions => redactions.isNotEmpty;

  @override
  String toString() =>
      'ScrubResult(${values.length} values, ${redactions.length} redacted)';
}

/// The outcome of scrubbing a free-text string (a log line, a breadcrumb
/// message, an exception message).
@immutable
class ScrubbedText {
  /// Creates a text scrub result.
  const new({required this.text, required this.redactions});

  /// A result with nothing redacted.
  const new clean(this.text) : redactions = const [];

  /// The scrubbed text.
  final String text;

  /// One record per redacted span.
  final List<RedactionRecord> redactions;

  /// Whether anything was redacted.
  bool get hasRedactions => redactions.isNotEmpty;

  @override
  String toString() => 'ScrubbedText(redacted: $hasRedactions)';
}
