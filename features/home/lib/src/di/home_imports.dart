import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Beranda container needs (ports only, ADR-0110).
void importHomeGlobals(GetIt child, GetIt root) {
  child
    ..registerFactory<CaseRepository>(() => root<CaseRepository>())
    ..registerFactory<ContentRepository>(() => root<ContentRepository>());
}
