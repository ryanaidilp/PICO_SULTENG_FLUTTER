/// No-op monitoring implementation for release builds.
///
/// This package provides empty implementations of monitoring interfaces,
/// allowing the debug monitoring tools to be stripped from release builds.
library;

export 'package:monitoring_api/monitoring_api.dart';

export 'src/consent_aware_monitoring.dart';
export 'src/di/injector.dart' show MonitoringImplPackageModule;
