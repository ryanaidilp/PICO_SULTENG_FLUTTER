import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Peta container needs (ports only).
void importPetaGlobals(GetIt child, GetIt root) {
  child.registerFactory<CaseRepository>(() => root<CaseRepository>());
}
