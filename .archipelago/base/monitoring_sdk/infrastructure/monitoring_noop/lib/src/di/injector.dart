import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:monitoring_noop/src/consent_aware_monitoring.dart';

/// Same class name as `monitoring_impl`'s own `MonitoringImplPackageModule`
/// -- the two packages are never imported together (build_prepare swaps
/// which one this app depends on), so only the import path changes on swap,
/// not any reference to this class.
///
/// Keeps a real (inert) stub registration: `AppMonitoring` is resolved
/// eagerly by starter features like `auth_sdk` whenever monitoring is
/// enabled, unconditionally, so release builds must have something to
/// resolve.
class MonitoringImplPackageModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    gh.lazySingleton<AppMonitoring>(ConsentAwareMonitoring.new);
  }
}
