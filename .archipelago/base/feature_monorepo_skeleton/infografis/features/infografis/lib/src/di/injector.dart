import 'package:dependencies/di.dart';
import 'package:infografis/src/di/injector.config.dart';

/// Local dependency injection for infografis package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`infografis_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `infografis_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initInfografisLocalDI', asExtension: false)
void initInfografisLocalDI(GetIt getIt) => $initInfografisLocalDI(getIt);
