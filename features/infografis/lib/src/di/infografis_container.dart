import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:infografis/src/di/infografis_imports.dart';
import 'package:infografis/src/di/injector.dart';

/// The Infografis feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importInfografisGlobals].
final infografisContainer = FeatureContainer(
  'infografis',
  root: GetIt.instance,
  build: buildInfografisContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildInfografisContainer(GetIt child, GetIt root) {
  importInfografisGlobals(child, root);
  initInfografisLocalDI(child);
}
