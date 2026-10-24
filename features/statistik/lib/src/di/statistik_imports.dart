import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Statistik container needs (ports only).
void importStatistikGlobals(GetIt child, GetIt root) {
  child.registerFactory<CaseRepository>(() => root<CaseRepository>());
}
