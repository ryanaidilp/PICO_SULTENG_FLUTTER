import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Layanan container needs (ports only).
void importLayananGlobals(GetIt child, GetIt root) {
  child.registerFactory<DirectoryRepository>(() => root<DirectoryRepository>());
}
