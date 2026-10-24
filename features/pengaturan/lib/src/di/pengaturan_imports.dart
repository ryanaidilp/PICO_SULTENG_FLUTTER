import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Pengaturan container needs (ports only).
void importPengaturanGlobals(GetIt child, GetIt root) {
  child
    ..registerFactory<SettingsRepository>(() => root<SettingsRepository>())
    ..registerFactory<LocalDataAdmin>(() => root<LocalDataAdmin>());
}
