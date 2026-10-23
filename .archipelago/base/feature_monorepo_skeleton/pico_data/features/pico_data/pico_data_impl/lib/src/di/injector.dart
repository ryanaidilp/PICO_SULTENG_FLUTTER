import 'package:dependencies/di.dart';

/// Registers the pico_data_impl package in the app root.
///
/// Annotate repositories, datasources and clients with `@lazySingleton`
/// (or `@injectable`); build_runner generates
/// `PicoDataImplPackageModule`, which the host injector
/// lists in `externalPackageModulesBefore`. Other features resolve these
/// types through the ports in `pico_data_api`.
@InjectableInit.microPackage()
void initPicoDataImplModule() {}
