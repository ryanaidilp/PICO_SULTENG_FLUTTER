import 'package:consent_api/consent_api.dart' show ConsentDecision;
import 'package:consent_api/src/consent/consent.dart' show ConsentDecision;
import 'package:consent_api/src/consent/consent_decision.dart'
    show ConsentDecision;
import 'package:consent_api/src/consent/consent_source.dart';
import 'package:dependencies_core/meta.dart';

/// One consent decision for one [scope] of one [subject].
///
/// [ConsentDecision] is keyed by the closed `ConsentPurpose` enum, which fits
/// app-level purposes. Mini-app grants are keyed by open strings, so they get
/// this sibling type. It reuses [ConsentSource], UTC timestamps and
/// `policyVersion` so the audit trail looks the same.
@immutable
// Not const: the initializer normalises `recordedAt` with `toUtc()`.
// ignore: prefer_const_constructors_in_immutables
class ScopedConsentDecision({
  /// `miniapp:<publisherId>/<miniAppId>`.
  required final String subject,

  /// Scope catalogue key, for example `identity`.
  required final String scope,

  /// Whether the user granted the scope.
  required final bool granted,
  required DateTime recordedAt,

  /// The surface the decision came from.
  final ConsentSource source = ConsentSource.user,

  /// The manifest version the user saw.
  final String? policyVersion,

  /// The server consent id, once synced.
  final String? recordId,
}) {
  /// Creates a decision. [recordedAt] is normalised to UTC.
  this;

  /// Rehydrates a decision from [toJson] output, or `null` when unusable.
  /// Callers treat `null` as "no decision", which is fail-closed.
  static ScopedConsentDecision? fromJson(Map<String, dynamic> json) {
    final subject = json['subject'];
    final scope = json['scope'];
    final granted = json['granted'];
    final recordedAtRaw = json['recorded_at'];
    if (subject is! String ||
        scope is! String ||
        granted is! bool ||
        recordedAtRaw is! String) {
      return null;
    }
    final recordedAt = DateTime.tryParse(recordedAtRaw);
    if (recordedAt == null) return null;

    final sourceKey = json['source'];
    final policyVersion = json['policy_version'];
    final recordId = json['record_id'];
    return ScopedConsentDecision(
      subject: subject,
      scope: scope,
      granted: granted,
      recordedAt: recordedAt,
      source: sourceKey is String
          ? ConsentSource.fromStorageKey(sourceKey) ?? ConsentSource.user
          : ConsentSource.user,
      policyVersion: policyVersion is String ? policyVersion : null,
      recordId: recordId is String ? recordId : null,
    );
  }

  /// When the decision was captured, in UTC.
  final DateTime recordedAt = recordedAt.toUtc();

  /// Serialises the decision for persistence.
  Map<String, dynamic> toJson() => {
    'subject': subject,
    'scope': scope,
    'granted': granted,
    'recorded_at': recordedAt.toIso8601String(),
    'source': source.storageKey,
    if (policyVersion != null) 'policy_version': policyVersion,
    if (recordId != null) 'record_id': recordId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopedConsentDecision &&
          subject == other.subject &&
          scope == other.scope &&
          granted == other.granted &&
          recordedAt == other.recordedAt &&
          source == other.source &&
          policyVersion == other.policyVersion &&
          recordId == other.recordId;

  @override
  int get hashCode => Object.hash(
    subject,
    scope,
    granted,
    recordedAt,
    source,
    policyVersion,
    recordId,
  );

  @override
  String toString() =>
      'ScopedConsentDecision($subject/$scope: $granted, '
      'via ${source.storageKey})';
}
