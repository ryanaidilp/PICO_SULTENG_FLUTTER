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
    this.alertsAvailable = false,
    this.alertsOn = false,
    this.alertsBusy = false,
    this.alertsDenied = false,
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

  /// Whether push exists in this build. False hides the notification row.
  final bool alertsAvailable;

  /// The switch: the user wants alerts and the OS permission is granted.
  final bool alertsOn;

  /// An enable or disable is running.
  final bool alertsBusy;

  /// The OS permission is missing: show "Buka pengaturan sistem".
  final bool alertsDenied;

  /// Copy with replaced fields.
  PengaturanState copyWith({
    PicoLocale? locale,
    PicoThemeMode? themeMode,
    int? cachedBytes,
    String? version,
    String? build,
    int? saveFailed,
    int? clearedCount,
    bool? alertsAvailable,
    bool? alertsOn,
    bool? alertsBusy,
    bool? alertsDenied,
  }) => PengaturanState(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    cachedBytes: cachedBytes ?? this.cachedBytes,
    version: version ?? this.version,
    build: build ?? this.build,
    saveFailed: saveFailed ?? this.saveFailed,
    clearedCount: clearedCount ?? this.clearedCount,
    alertsAvailable: alertsAvailable ?? this.alertsAvailable,
    alertsOn: alertsOn ?? this.alertsOn,
    alertsBusy: alertsBusy ?? this.alertsBusy,
    alertsDenied: alertsDenied ?? this.alertsDenied,
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
    alertsAvailable,
    alertsOn,
    alertsBusy,
    alertsDenied,
  ];
}
