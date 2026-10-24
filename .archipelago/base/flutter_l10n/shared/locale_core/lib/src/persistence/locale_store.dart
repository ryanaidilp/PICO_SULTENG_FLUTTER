/// Durable storage for the user's chosen app locale.
///
/// `locale_core` owns both halves of the locale-persistence contract — writing
/// the choice on change and restoring it at boot — and this is the seam that
/// decides *where* the choice lands.
///
/// The default implementation is `SharedPreferencesLocaleStore`. Substitute a
/// different one (an encrypted store, a server-synced profile setting, an
/// in-memory fake in tests) by assigning `AppLocaleController.store` before
/// `AppLocaleController.restore()` runs in `bootstrap.dart`.
///
/// A language tag is a UI preference, not a secret — do not extend this store
/// to carry user identifiers.
abstract interface class LocaleStore() {
  /// The persisted BCP-47 language tag (e.g. `en`, `id`), or `null` when the
  /// user has never made an explicit choice.
  Future<String?> read();

  /// Persists [languageTag] as the user's explicit choice.
  Future<void> write(String languageTag);

  /// Forgets the persisted choice, so the next cold start falls back to the
  /// default locale.
  Future<void> clear();
}
