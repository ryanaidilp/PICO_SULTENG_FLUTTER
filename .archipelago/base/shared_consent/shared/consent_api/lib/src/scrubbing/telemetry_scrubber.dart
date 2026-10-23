import 'package:consent_api/src/scrubbing/redaction_record.dart';
import 'package:consent_api/src/scrubbing/scrub_result.dart';
import 'package:consent_api/src/scrubbing/scrub_rules.dart';

/// Removes personal data from a telemetry payload immediately before it is
/// handed to a vendor SDK.
///
/// Runs **after** the consent gate and **before** dispatch. Consent answers
/// "may we send anything at all?"; the scrubber answers "is this specific
/// payload safe to send?". Both are needed: a user can lawfully consent to
/// product analytics without consenting to their email address being in it.
///
/// One instance serves analytics events, monitoring log lines and crash
/// breadcrumbs so there is a single rule set rather than three.
///
/// This is not the same thing as `SharedEventSanitizer`, which normalises
/// names and truncates lengths for *vendor compatibility* and never inspects
/// a value's content.
abstract class TelemetryScrubber() {
  /// The policy this scrubber enforces.
  ScrubRules get rules;

  /// Total values redacted since construction (or the last
  /// [resetRedactionCount]).
  ///
  /// Exposed so redaction is observable rather than silent — a spike here
  /// after a release usually means someone started sending a new personal
  /// field, which is exactly the signal a privacy review needs.
  int get redactionCount;

  /// Emits every redaction as it happens. Broadcast.
  Stream<RedactionRecord> get redactions;

  /// Scrubs a structured payload (event properties, breadcrumb data, error
  /// context).
  ///
  /// [channel] labels the telemetry surface for observability.
  ScrubResult scrubProperties(
    Map<String, dynamic> properties, {
    String channel = 'unknown',
  });

  /// Scrubs free text (a log line, a breadcrumb message, an exception
  /// message), redacting only the offending whitespace-delimited spans so the
  /// rest of the message stays readable.
  ScrubbedText scrubText(
    String text, {
    String channel = 'unknown',
    String key = 'message',
  });

  /// Resets [redactionCount] to zero.
  void resetRedactionCount();
}
