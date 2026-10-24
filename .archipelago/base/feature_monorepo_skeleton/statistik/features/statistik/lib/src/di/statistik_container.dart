import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:statistik/src/di/injector.dart';
import 'package:statistik/src/di/statistik_imports.dart';

/// The Statistik feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importStatistikGlobals].
final statistikContainer = FeatureContainer(
  'statistik',
  root: GetIt.instance,
  build: buildStatistikContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildStatistikContainer(GetIt child, GetIt root) {
  importStatistikGlobals(child, root);
  initStatistikLocalDI(child);
}
