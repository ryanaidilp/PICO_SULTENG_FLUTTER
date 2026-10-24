import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:peta/src/di/injector.dart';
import 'package:peta/src/di/peta_imports.dart';

/// The Peta feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importPetaGlobals].
final petaContainer = FeatureContainer(
  'peta',
  root: GetIt.instance,
  build: buildPetaContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildPetaContainer(GetIt child, GetIt root) {
  importPetaGlobals(child, root);
  initPetaLocalDI(child);
}
