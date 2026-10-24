import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Vaksin container needs (ports only).
void importVaksinGlobals(GetIt child, GetIt root) {
  child
    ..registerFactory<StatsRepository>(() => root<StatsRepository>())
    ..registerFactory<DirectoryRepository>(() => root<DirectoryRepository>());
}
