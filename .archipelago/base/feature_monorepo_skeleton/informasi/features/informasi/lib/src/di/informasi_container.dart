import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:informasi/src/di/informasi_imports.dart';
import 'package:informasi/src/di/injector.dart';

/// The Informasi feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importInformasiGlobals].
final informasiContainer = FeatureContainer(
  'informasi',
  root: GetIt.instance,
  build: buildInformasiContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildInformasiContainer(GetIt child, GetIt root) {
  importInformasiGlobals(child, root);
  initInformasiLocalDI(child);
}
