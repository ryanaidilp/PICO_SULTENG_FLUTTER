import 'package:dependencies/di.dart';
import 'package:peta/src/di/injector.config.dart';

/// Local dependency injection for peta package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`peta_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `peta_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initPetaLocalDI', asExtension: false)
void initPetaLocalDI(GetIt getIt) => $initPetaLocalDI(getIt);
