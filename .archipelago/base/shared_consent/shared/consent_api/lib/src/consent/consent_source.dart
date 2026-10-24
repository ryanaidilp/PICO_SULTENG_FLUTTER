/// How a consent decision was captured.
///
/// Persisted alongside the decision because proving *how* consent was obtained
/// is itself a compliance requirement — an auditor asks "who agreed, when, and
/// through what surface", not just "is tracking on".
enum ConsentSource(
  /// Stable key used when persisting a decision.
  final String storageKey,
) {
  /// Captured from an explicit user interaction (consent sheet, settings).
  user('user'),

  /// Forced open by a debug-build-only override. Never valid in production.
  debugOverride('debug_override'),

  /// Synced from a server-side consent record (e.g. account-level preference).
  remoteSync('remote_sync'),

  /// Written by a data migration from a previous consent representation.
  migration('migration');

  /// Resolves a source from its [storageKey], or `null` when unknown.
  static ConsentSource? fromStorageKey(String key) {
    for (final source in ConsentSource.values) {
      if (source.storageKey == key) return source;
    }
    return null;
  }
}
