import 'package:dependencies/di.dart';
import 'package:layanan/src/di/injector.config.dart';

/// Local dependency injection for layanan package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`layanan_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `layanan_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initLayananLocalDI', asExtension: false)
void initLayananLocalDI(GetIt getIt) => $initLayananLocalDI(getIt);
