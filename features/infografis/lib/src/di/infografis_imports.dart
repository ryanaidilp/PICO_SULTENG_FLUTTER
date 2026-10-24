import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Infografis container needs (ports only).
void importInfografisGlobals(GetIt child, GetIt root) {
  child.registerFactory<ContentRepository>(() => root<ContentRepository>());
}
