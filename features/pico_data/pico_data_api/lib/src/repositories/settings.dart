/// App theme choice (C08).
enum PicoThemeMode {
  /// Follow the OS.
  system,

  /// Light.
  light,

  /// Dark.
  dark,
}

/// User preferences kept in shared_preferences (C08). Language lives in
/// `locale_core`.
abstract interface class SettingsRepository {
  /// Current theme mode, default [PicoThemeMode.system].
  PicoThemeMode get themeMode;

  /// Emits on every change.
  Stream<PicoThemeMode> get themeModeChanges;

  /// Saves the theme mode.
  Future<void> setThemeMode(PicoThemeMode mode);

  /// The user's alerts switch, not the OS permission.
  bool get dataUpdateAlertsWanted;

  /// Saves the alerts switch.
  Future<void> setDataUpdateAlertsWanted(bool wanted);
}

/// What turning on "Kabar pembaruan data" did (ADR-0112).
enum DataUpdateAlertsOutcome {
  /// Consent granted, OS permission granted, topic subscribed.
  enabled,

  /// The user refused the OS permission. Consent was revoked again.
  denied,

  /// The push service failed. Nothing is left switched on.
  failed,
}

/// The push opt-in flow behind the Pengaturan switch (S51, ADR-0112).
///
/// The host implements it on top of the generated push contract. A feature
/// reads this port only, so it never imports a push package. No method
/// here may reach the push vendor before [enable] is called.
abstract interface class DataUpdateAlerts {
  /// Whether push exists in this build (a push provider is wired and the
  /// flavour has an App ID). When false, Pengaturan hides the whole row.
  bool get available;

  /// Whether the OS notification permission is granted right now. Never
  /// prompts.
  Future<bool> osPermissionGranted();

  /// Steps 3 to 4 of ADR-0112 after the user accepted the explain sheet:
  /// record consent, ask the OS, subscribe to topic `data_update`. Writes
  /// nothing to the vendor when the user refuses the OS permission.
  Future<DataUpdateAlertsOutcome> enable();

  /// Step 6: unsubscribe from the topic, opt out and revoke consent.
  Future<void> disable();

  /// Opens the OS settings page of this app, for the denied state.
  Future<void> openSystemSettings();
}

/// The port when no push provider exists: hidden, and does nothing.
class const UnavailableDataUpdateAlerts() implements DataUpdateAlerts {
  @override
  bool get available => false;

  @override
  Future<bool> osPermissionGranted() async => false;

  @override
  Future<DataUpdateAlertsOutcome> enable() async =>
      DataUpdateAlertsOutcome.failed;

  @override
  Future<void> disable() async {}

  @override
  Future<void> openSystemSettings() async {}
}
