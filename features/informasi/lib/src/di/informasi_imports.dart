import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Forwards the root types the Informasi container needs (ports only). The
/// articles are bundled assets; only the partners come from a port.
void importInformasiGlobals(GetIt child, GetIt root) {
  child.registerFactory<ContentRepository>(() => root<ContentRepository>());
}
