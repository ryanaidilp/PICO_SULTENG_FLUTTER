import 'package:dependencies/state.dart';
import 'package:locale_core/locale_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_event.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Reads the app version and build.
typedef VersionLoader = Future<({String version, String build})> Function();

Future<({String version, String build})> _packageVersion() async {
  final i = await PackageInfo.fromPlatform();
  return (version: i.version, build: i.buildNumber);
}

/// Writes language and theme through their owners (C08) and clears saved data.
class PengaturanBloc extends Bloc<PengaturanEvent, PengaturanState> {
  /// Creates the bloc. [setLocale] and [loadVersion] are for tests.
  new(
    this._settings,
    this._admin, {
    Future<void> Function(PicoLocale)? setLocale,
    VersionLoader? loadVersion,
  }) : _setLocale = setLocale ?? AppLocaleController.setLocale,
       _loadVersion = loadVersion ?? _packageVersion,
       super(
         PengaturanState(
           locale: LocaleSettings.currentLocale,
           themeMode: _settings.themeMode,
         ),
       ) {
    on<PengaturanStarted>((e, emit) async {
      emit(state.copyWith(cachedBytes: await _bytes()));
      try {
        final v = await _loadVersion();
        emit(state.copyWith(version: v.version, build: v.build));
      } on Object {
        // No version row without a version; the rest of the page still works.
      }
    });
    on<LanguageChosen>((e, emit) async {
      if (e.locale == state.locale) return;
      try {
        await _setLocale(e.locale);
        emit(state.copyWith(locale: e.locale));
      } on Object {
        emit(state.copyWith(saveFailed: state.saveFailed + 1));
      }
    });
    on<ThemeChosen>((e, emit) async {
      if (e.mode == state.themeMode) return;
      try {
        await _settings.setThemeMode(e.mode);
        emit(state.copyWith(themeMode: e.mode));
      } on Object {
        emit(state.copyWith(saveFailed: state.saveFailed + 1));
      }
    });
    on<SavedDataCleared>((e, emit) async {
      try {
        await _admin.clearAll();
        emit(
          state.copyWith(
            cachedBytes: await _bytes(),
            clearedCount: state.clearedCount + 1,
          ),
        );
      } on Object {
        emit(state.copyWith(saveFailed: state.saveFailed + 1));
      }
    });
  }

  final SettingsRepository _settings;
  final LocalDataAdmin _admin;
  final Future<void> Function(PicoLocale) _setLocale;
  final VersionLoader _loadVersion;

  Future<int> _bytes() async {
    try {
      return await _admin.cachedBytes();
    } on Object {
      return 0;
    }
  }
}
