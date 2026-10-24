/// Injectable `@Named` keys for monitoring vendor registrations.
///
/// Use these constants to keep naming consistent between vendor
/// implementations and the fanout orchestrator.
///
/// Example:
/// ```dart
/// @Named(MonitoringInjectorKey.crashlytics)
/// @LazySingleton(as: AppMonitoringVendor)
/// class CrashlyticsMonitoringVendor implements AppMonitoringVendor { ... }
/// ```
abstract final class MonitoringInjectorKey() {
  /// Key for Firebase Crashlytics vendor.
  static const String crashlytics = 'crashlytics';

  /// Key for Sentry vendor.
  static const String sentry = 'sentry';

  /// Key for New Relic vendor.
  static const String newrelic = 'newrelic';

  /// Key for Grafana Loki + Tempo vendor.
  static const String grafana = 'grafana';
}
