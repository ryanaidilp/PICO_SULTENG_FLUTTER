import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// Module for registering external dependencies.
@module
abstract class MonitoringRegisterModule() {
  /// Collects the `AppMonitoringVendor` registered under each known
  /// `@Named(...)` key — i.e. exactly the vendor packages this project has
  /// installed (`crashlytics_monitoring_impl`, `sentry_monitoring_impl`,
  /// `grafana_monitoring_impl`, `newrelic_monitoring_impl`).
  ///
  /// Deliberately does NOT use `GetIt.getAll<AppMonitoringVendor>()`: as of
  /// the pinned `get_it` version, `getAll<T>()` throws a `StateError` when
  /// **no** registration of `T` exists under any name — which is exactly
  /// the default `monitoringVendors: []` complement (this package does not
  /// bundle any vendor). Checking
  /// `isRegistered` per known key first avoids ever calling `getAll`/`get`
  /// on a key that was never registered.
  ///
  /// Reads `GetIt.instance` directly rather than the `gh` handed to
  /// `init()`: every vendor package registers against the same global
  /// container in production (`apps/<app>/lib/di/injector.dart` always
  /// calls `$initGetIt(GetIt.instance)`), matching the same
  /// `GetIt.instance`-over-`gh` idiom used by
  /// `AiChatImplGlobalModule`/`SocialAuthImplGlobalModule`.
  ///
  /// Each vendor is built in its own try/catch: a vendor that cannot be
  /// constructed (e.g. Crashlytics before `flutterfire configure`, so
  /// `Firebase.initializeApp()` failed) is skipped with a debug message
  /// instead of failing `AppMonitoring` and, with it, app boot.
  @lazySingleton
  List<AppMonitoringVendor> get monitoringVendors {
    final getIt = GetIt.instance;
    final vendors = <AppMonitoringVendor>[];
    for (final name in const [
      MonitoringInjectorKey.crashlytics,
      MonitoringInjectorKey.sentry,
      MonitoringInjectorKey.grafana,
      MonitoringInjectorKey.newrelic,
    ]) {
      if (!getIt.isRegistered<AppMonitoringVendor>(instanceName: name)) {
        continue;
      }
      try {
        vendors.add(getIt<AppMonitoringVendor>(instanceName: name));
      } catch (error) {
        debugPrint('[monitoring] vendor "$name" disabled: $error');
      }
    }
    return vendors;
  }
}
