import 'package:dependencies/di.dart';

export 'injector.module.dart' show MonitoringImplPackageModule;

/// Configures dependency injection for monitoring_impl package.
@InjectableInit.microPackage()
void initMonitoringImplModule() {}
