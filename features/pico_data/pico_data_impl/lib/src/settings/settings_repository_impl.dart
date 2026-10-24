import 'dart:async';

import 'package:pico_data_api/pico_data_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preference keys of C08. Stable: never reuse a key for a new meaning.
abstract final class PicoSettingsKeys {
  /// `system`, `light` or `dark`.
  static const themeMode = 'pico.settings.theme_mode';

  /// Bool, the user's alerts switch.
  static const dataUpdateAlerts = 'pico.settings.data_update_alerts';
}

/// [SettingsRepository] on shared_preferences (C08). It is loaded before the
/// first frame, so the theme never flashes. A read problem gives the default,
/// and a failed write keeps the old value and emits nothing.
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates the repository over loaded [prefs].
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<PicoThemeMode> _changes =
      StreamController<PicoThemeMode>.broadcast();

  @override
  PicoThemeMode get themeMode {
    try {
      final raw = _prefs.getString(PicoSettingsKeys.themeMode);
      return PicoThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => PicoThemeMode.system,
      );
    } on Object {
      return PicoThemeMode.system;
    }
  }

  @override
  Stream<PicoThemeMode> get themeModeChanges => _changes.stream;

  @override
  Future<void> setThemeMode(PicoThemeMode mode) async {
    final ok = await _write(
      () => _prefs.setString(PicoSettingsKeys.themeMode, mode.name),
    );
    if (ok) _changes.add(mode);
  }

  @override
  bool get dataUpdateAlertsWanted {
    try {
      return _prefs.getBool(PicoSettingsKeys.dataUpdateAlerts) ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setDataUpdateAlertsWanted(bool wanted) async {
    await _write(
      () => _prefs.setBool(PicoSettingsKeys.dataUpdateAlerts, wanted),
    );
  }

  Future<bool> _write(Future<bool> Function() write) async {
    try {
      return await write();
    } on Object {
      return false;
    }
  }
}
