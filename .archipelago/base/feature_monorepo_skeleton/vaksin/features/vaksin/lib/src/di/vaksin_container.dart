import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:vaksin/src/di/injector.dart';
import 'package:vaksin/src/di/vaksin_imports.dart';

/// The Vaksin feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importVaksinGlobals].
final vaksinContainer = FeatureContainer(
  'vaksin',
  root: GetIt.instance,
  build: buildVaksinContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildVaksinContainer(GetIt child, GetIt root) {
  importVaksinGlobals(child, root);
  initVaksinLocalDI(child);
}
