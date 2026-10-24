import 'package:dependencies/di.dart';
import 'package:vaksin/src/di/injector.config.dart';

/// Local dependency injection for vaksin package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`vaksin_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `vaksin_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initVaksinLocalDI', asExtension: false)
void initVaksinLocalDI(GetIt getIt) => $initVaksinLocalDI(getIt);
