import 'package:dependencies/di.dart';
import 'package:statistik/src/di/injector.config.dart';

/// Local dependency injection for statistik package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`statistik_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `statistik_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initStatistikLocalDI', asExtension: false)
void initStatistikLocalDI(GetIt getIt) => $initStatistikLocalDI(getIt);
