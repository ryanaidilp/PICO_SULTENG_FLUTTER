import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:home/src/di/home_imports.dart';
import 'package:home/src/di/injector.dart';

/// The Home feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importHomeGlobals].
final homeContainer = FeatureContainer(
  'home',
  root: GetIt.instance,
  build: buildHomeContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildHomeContainer(GetIt child, GetIt root) {
  importHomeGlobals(child, root);
  initHomeLocalDI(child);
}
