import 'package:consent_api/src/consent/consent_source.dart';
import 'package:consent_api/src/scoped/scoped_consent_decision.dart';

/// Answers "did the user grant `scope` to `subject`?" for mini-apps.
///
/// Like `ConsentGate`, [isGranted] is synchronous and fail-closed: `false`
/// until the user has decided.
abstract interface class ScopedConsentGate() {
  /// Whether [scope] is currently granted to [subject].
  bool isGranted(String subject, String scope);

  /// The latest decision per scope for [subject].
  List<ScopedConsentDecision> decisionsFor(String subject);

  /// Subjects with at least one granted scope. Drives the settings list.
  Set<String> get subjects;

  /// Emits the subject whose decisions changed. Broadcast.
  Stream<String> get changes;

  /// Records [decisions] for [subject] as one atomic write.
  ///
  /// [recordId] is the server consent id returned by `ScopedConsentSync.push`.
  Future<void> recordAll(
    String subject,
    Map<String, bool> decisions, {
    ConsentSource source,
    String? policyVersion,
    String? recordId,
  });

  /// Stores [decisions] as given, overwriting the same subject and scope.
  ///
  /// For decisions pulled from the server, which keep their own timestamp,
  /// source and record id.
  Future<void> putAll(Iterable<ScopedConsentDecision> decisions);

  /// "Remove access": records a refusal for every scope of [subject].
  ///
  /// The refusals stay as audit records. The subject leaves [subjects].
  Future<void> revokeSubject(String subject);
}

/// A gate that denies everything and cannot record. The safe default when no
/// real gate is wired.
class const DeniedScopedConsentGate() implements ScopedConsentGate {
  /// Creates the always-denying gate.
  this;

  @override
  bool isGranted(String subject, String scope) => false;

  @override
  List<ScopedConsentDecision> decisionsFor(String subject) => const [];

  @override
  Set<String> get subjects => const {};

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<void> recordAll(
    String subject,
    Map<String, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    String? policyVersion,
    String? recordId,
  }) => throw StateError(_notInstalled);

  @override
  Future<void> putAll(Iterable<ScopedConsentDecision> decisions) =>
      throw StateError(_notInstalled);

  @override
  Future<void> revokeSubject(String subject) => throw StateError(_notInstalled);

  static const String _notInstalled =
      'No ScopedConsentGate is installed. Call ConsentInitializer.initialize '
      '(consent_impl) during bootstrap.';
}
