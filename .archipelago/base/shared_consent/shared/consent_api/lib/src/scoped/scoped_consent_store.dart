import 'package:consent_api/src/scoped/scoped_consent_decision.dart';

/// Persistence port for scoped decisions. Same shape as `ConsentStore`.
abstract interface class ScopedConsentStore() {
  /// Reads every stored decision. Empty when nothing is stored.
  Future<List<ScopedConsentDecision>> read();

  /// Replaces everything stored with [all].
  Future<void> write(List<ScopedConsentDecision> all);

  /// Removes the persisted record entirely.
  Future<void> clear();
}

/// A [ScopedConsentStore] that keeps decisions in memory only.
class InMemoryScopedConsentStore({List<ScopedConsentDecision>? initial})
    implements ScopedConsentStore {
  /// Creates a store, optionally seeded with [initial] decisions.
  this;

  List<ScopedConsentDecision> _decisions = [...?initial];

  @override
  Future<List<ScopedConsentDecision>> read() async => [..._decisions];

  @override
  Future<void> write(List<ScopedConsentDecision> all) async {
    _decisions = [...all];
  }

  @override
  Future<void> clear() async {
    _decisions = [];
  }
}
