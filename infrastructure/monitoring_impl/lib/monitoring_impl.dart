/// Vendor-agnostic monitoring fanout orchestration.
///
/// This package never bundles a vendor implementation directly — each
/// monitoring vendor (Crashlytics, Sentry, Grafana, New Relic) ships as its
/// own brick, generated only when the user selects it (see
/// `monitoringVendors` in `flutter_modular_monorepo`). Install the
/// corresponding vendor brick and register its DI module to wire it into
/// this fanout.
library;

export 'package:monitoring_api/monitoring_api.dart';

export 'src/consent_aware_monitoring.dart';
export 'src/di/injector.dart' show MonitoringImplPackageModule;
export 'src/monitoring_fanout_impl.dart';
