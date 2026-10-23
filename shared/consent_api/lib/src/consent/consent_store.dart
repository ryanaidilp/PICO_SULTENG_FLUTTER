import 'package:consent_api/src/consent/consent_state.dart';

/// Persistence port for [ConsentState].
///
/// Kept as a port (rather than taking a `SharedPreferences` dependency here)
/// so `consent_api` stays dependency-free and so apps can swap in encrypted
/// or server-backed storage without touching the gate.
abstract interface class ConsentStore() {
  /// Reads the persisted state, or `null` when nothing has been stored.
  Future<ConsentState?> read();

  /// Persists [state], replacing anything previously stored.
  Future<void> write(ConsentState state);

  /// Removes the persisted record entirely.
  Future<void> clear();
}

/// A [ConsentStore] that keeps state in memory only.
///
/// Used by tests and by builds that must not persist a consent record.
class InMemoryConsentStore({ConsentState? initial}) implements ConsentStore {
  /// Creates a store, optionally seeded with [initial] state.
  this;

  ConsentState? _state = initial;

  @override
  Future<ConsentState?> read() async => _state;

  @override
  Future<void> write(ConsentState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}
