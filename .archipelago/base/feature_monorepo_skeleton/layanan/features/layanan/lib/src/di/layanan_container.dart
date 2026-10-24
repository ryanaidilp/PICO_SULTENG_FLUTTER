import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:layanan/src/di/injector.dart';
import 'package:layanan/src/di/layanan_imports.dart';

/// The Layanan feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importLayananGlobals].
final layananContainer = FeatureContainer(
  'layanan',
  root: GetIt.instance,
  build: buildLayananContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildLayananContainer(GetIt child, GetIt root) {
  importLayananGlobals(child, root);
  initLayananLocalDI(child);
}
