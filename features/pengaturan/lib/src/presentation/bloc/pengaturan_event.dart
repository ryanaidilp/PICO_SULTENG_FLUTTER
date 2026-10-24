import 'package:locale_core/locale_core.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Events of the settings page.
abstract class PengaturanEvent {
  const new();
}

/// Load the saved size and the version.
final class PengaturanStarted extends PengaturanEvent {
  /// Creates the event.
  const new();
}

/// The user chose a language.
final class LanguageChosen extends PengaturanEvent {
  /// Creates the event.
  const new(this.locale);

  /// The language.
  final PicoLocale locale;
}

/// The user chose a theme.
final class ThemeChosen extends PengaturanEvent {
  /// Creates the event.
  const new(this.mode);

  /// The theme mode.
  final PicoThemeMode mode;
}

/// The user confirmed "Hapus data tersimpan".
final class SavedDataCleared extends PengaturanEvent {
  /// Creates the event.
  const new();
}
