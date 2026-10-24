import 'package:dependencies/di.dart';
import 'package:pengaturan/src/di/injector.config.dart';

/// Local dependency injection for pengaturan package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`pengaturan_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `pengaturan_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initPengaturanLocalDI', asExtension: false)
void initPengaturanLocalDI(GetIt getIt) => $initPengaturanLocalDI(getIt);
