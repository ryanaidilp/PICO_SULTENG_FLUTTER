import 'package:consent_api/src/scoped/scoped_consent_decision.dart';

/// Port to the server record of scoped consent. The host app implements it.
///
/// The server holds the authoritative record because the token mint verifies
/// it. A grant that exists only on the device cannot produce a token.
abstract interface class ScopedConsentSync() {
  /// Whether a backend is wired. When `false`, scopes that need a server
  /// record (`identity`) cannot be granted and the UI should hide them.
  bool get isAvailable;

  /// Upserts [decisions] for [subject] and returns the server record id
  /// (empty when there is no server record).
  ///
  /// Throws on failure. The caller must then not record anything locally.
  Future<String> push(
    String subject,
    Map<String, bool> decisions,
    String policyVersion,
  );

  /// Reads the server's decisions. Callers store them with
  /// `ConsentSource.remoteSync`.
  Future<List<ScopedConsentDecision>> pull();
}

/// Default sync: there is no backend, so consent stays on the device.
///
/// [push] succeeds with an empty record id, so consent is recorded locally.
class const NoopScopedConsentSync() implements ScopedConsentSync {
  /// Creates the no-op sync.
  this;

  @override
  bool get isAvailable => false;

  @override
  Future<String> push(
    String subject,
    Map<String, bool> decisions,
    String policyVersion,
  ) async => '';

  @override
  Future<List<ScopedConsentDecision>> pull() async => const [];
}
