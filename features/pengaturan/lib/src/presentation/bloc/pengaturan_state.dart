import 'package:dependencies/equality.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// What the settings page shows.
final class PengaturanState extends Equatable {
  /// Creates a state.
  const new({
    required this.locale,
    this.themeMode = PicoThemeMode.system,
    this.cachedBytes,
    this.version,
    this.build,
    this.saveFailed = 0,
    this.clearedCount = 0,
  });

  /// Chosen language.
  final PicoLocale locale;

  /// Chosen theme.
  final PicoThemeMode themeMode;

  /// Saved data size, null until read.
  final int? cachedBytes;

  /// App version, null until read.
  final String? version;

  /// Build number.
  final String? build;

  /// Counts failed writes, so a listener shows the toast once per failure.
  final int saveFailed;

  /// Counts completed clears, so a listener shows the toast once per clear.
  final int clearedCount;

  /// Copy with replaced fields.
  PengaturanState copyWith({
    PicoLocale? locale,
    PicoThemeMode? themeMode,
    int? cachedBytes,
    String? version,
    String? build,
    int? saveFailed,
    int? clearedCount,
  }) => PengaturanState(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    cachedBytes: cachedBytes ?? this.cachedBytes,
    version: version ?? this.version,
    build: build ?? this.build,
    saveFailed: saveFailed ?? this.saveFailed,
    clearedCount: clearedCount ?? this.clearedCount,
  );

  @override
  List<Object?> get props => [
    locale,
    themeMode,
    cachedBytes,
    version,
    build,
    saveFailed,
    clearedCount,
  ];
}
