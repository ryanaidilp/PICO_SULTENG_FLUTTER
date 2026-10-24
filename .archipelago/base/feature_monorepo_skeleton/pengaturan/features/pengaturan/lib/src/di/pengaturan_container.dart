import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:pengaturan/src/di/injector.dart';
import 'package:pengaturan/src/di/pengaturan_imports.dart';

/// The Pengaturan feature's own DI container.
///
/// A child GetIt built when the first page takes a lease and torn down when
/// the last lease is released. It holds the feature's repositories,
/// datasources and use cases, plus the root types forwarded by
/// [importPengaturanGlobals].
final pengaturanContainer = FeatureContainer(
  'pengaturan',
  root: GetIt.instance,
  build: buildPengaturanContainer,
);

/// Fills [child]: the imports first, then the generated local DI.
///
/// A singleton registered here by hand that holds resources needs
/// `dispose:`, so the container's teardown releases it.
void buildPengaturanContainer(GetIt child, GetIt root) {
  importPengaturanGlobals(child, root);
  initPengaturanLocalDI(child);
}
