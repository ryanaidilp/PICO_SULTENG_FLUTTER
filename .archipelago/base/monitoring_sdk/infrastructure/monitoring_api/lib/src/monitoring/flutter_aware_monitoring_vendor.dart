import 'package:flutter/foundation.dart';

/// Extension of `AppMonitoringVendor` for vendors that have a dedicated
/// Flutter error API (e.g., Firebase Crashlytics).
///
/// `MonitoringFanoutImpl.recordFlutterError` checks for this interface so the
/// vendor can use its framework-specific error recording API instead of the
/// generic `AppMonitoringVendor.recordError`.
abstract interface class FlutterAwareMonitoringVendor() {
  /// Record a Flutter framework error using the vendor's dedicated API.
  ///
  /// Reached from the app's [FlutterError.onError] via
  /// `AppMonitoring.recordFlutterError`. Implementations should use the
  /// vendor-specific Flutter error API (e.g., `FirebaseCrashlytics.instance.recordFlutterError`)
  /// which preserves widget tree information.
  Future<void> recordFlutterError(FlutterErrorDetails details);
}
