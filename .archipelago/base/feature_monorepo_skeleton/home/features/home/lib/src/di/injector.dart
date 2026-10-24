import 'package:dependencies/di.dart';
import 'package:home/src/di/injector.config.dart';

/// Local dependency injection for home package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`home_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `home_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initHomeLocalDI', asExtension: false)
void initHomeLocalDI(GetIt getIt) => $initHomeLocalDI(getIt);
