import 'package:dependencies/di.dart';
import 'package:informasi/src/di/injector.config.dart';

/// Local dependency injection for informasi package.
///
/// Annotate repositories, datasources and use cases with `@injectable` or
/// `@lazySingleton`; build_runner adds them here. This runs against the
/// feature's own container (`informasi_container.dart`),
/// never the app root. A constructor parameter of a root type must be
/// forwarded in `informasi_imports.dart`; list it in
/// `ignoreUnregisteredTypes` so the generator does not warn.
@InjectableInit(initializerName: r'$initInformasiLocalDI', asExtension: false)
void initInformasiLocalDI(GetIt getIt) => $initInformasiLocalDI(getIt);
