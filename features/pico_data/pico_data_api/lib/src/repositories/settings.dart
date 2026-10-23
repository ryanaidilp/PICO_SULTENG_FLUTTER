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
