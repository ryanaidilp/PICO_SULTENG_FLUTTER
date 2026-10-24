import 'package:consent_api/src/consent/consent_purpose.dart';
import 'package:consent_api/src/consent/consent_source.dart';
import 'package:dependencies_core/meta.dart';

/// A single, auditable consent decision for one [ConsentPurpose].
///
/// [recordedAt] and [source] exist so the app can *prove* consent, not merely
/// honour it. Both are persisted.
@immutable
// This constructor cannot be made const: the initializer normalises
// `recordedAt` via `DateTime.toUtc()`, an instance method call that is not a
// compile-time constant expression, so `const` is not a legal declaration
// here despite the class otherwise satisfying @immutable (all fields are
// final and never mutated after construction).
// ignore: prefer_const_constructors_in_immutables
class ConsentDecision({
  /// The purpose this decision applies to.
  required final ConsentPurpose purpose,

  /// Whether the user granted the purpose.
  required final bool granted,
  required DateTime recordedAt,

  /// The surface the decision came from.
  final ConsentSource source = ConsentSource.user,

  /// Version of the privacy policy / consent copy shown at capture time.
  ///
  /// Lets an app re-prompt when the policy materially changes.
  final String? policyVersion,
}) {
  /// Creates a decision. [recordedAt] is normalised to UTC.
  this;

  /// Rehydrates a decision from [toJson] output.
  ///
  /// Returns `null` when the payload is unusable (unknown purpose, malformed
  /// timestamp). Callers treat `null` as "no decision", which is fail-closed.
  static ConsentDecision? fromJson(Map<String, dynamic> json) {
    final purposeKey = json['purpose'];
    final granted = json['granted'];
    final recordedAtRaw = json['recorded_at'];
    if (purposeKey is! String || granted is! bool || recordedAtRaw is! String) {
      return null;
    }
    final purpose = ConsentPurpose.fromStorageKey(purposeKey);
    final recordedAt = DateTime.tryParse(recordedAtRaw);
    if (purpose == null || recordedAt == null) return null;

    final sourceKey = json['source'];
    final policyVersion = json['policy_version'];
    return ConsentDecision(
      purpose: purpose,
      granted: granted,
      recordedAt: recordedAt,
      source: sourceKey is String
          ? ConsentSource.fromStorageKey(sourceKey) ?? ConsentSource.user
          : ConsentSource.user,
      policyVersion: policyVersion is String ? policyVersion : null,
    );
  }

  /// When the decision was captured, in UTC.
  final DateTime recordedAt = recordedAt.toUtc();

  /// Serialises the decision for persistence.
  Map<String, dynamic> toJson() => {
    'purpose': purpose.storageKey,
    'granted': granted,
    'recorded_at': recordedAt.toIso8601String(),
    'source': source.storageKey,
    if (policyVersion != null) 'policy_version': policyVersion,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentDecision &&
          runtimeType == other.runtimeType &&
          purpose == other.purpose &&
          granted == other.granted &&
          recordedAt == other.recordedAt &&
          source == other.source &&
          policyVersion == other.policyVersion;

  @override
  int get hashCode =>
      Object.hash(purpose, granted, recordedAt, source, policyVersion);

  @override
  String toString() =>
      'ConsentDecision(${purpose.storageKey}: $granted, '
      'at ${recordedAt.toIso8601String()}, via ${source.storageKey})';
}
