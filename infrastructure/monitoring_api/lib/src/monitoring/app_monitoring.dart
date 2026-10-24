import 'package:flutter/foundation.dart';
import 'package:monitoring_api/src/monitoring/monitoring_level.dart';

/// App-facing contract for monitoring and crash reporting.
///
/// The concrete implementation (`MonitoringFanoutImpl`, bound as
/// `AppMonitoring` through `ConsentAwareMonitoring`) fans out every call
/// to all enabled `AppMonitoringVendor`s registered via DI.
/// `monitoring_noop` (`ConsentAwareMonitoring`, inert) is an opt-in swap via
/// build_prepare; it is not the default.
///
/// Obtain via `getIt<AppMonitoring>()` — never import vendor packages
/// directly from app code.
///
/// Example:
/// ```dart
/// final monitoring = getIt<AppMonitoring>();
/// await monitoring.initialize();
///
/// monitoring.log('Payment started', tag: 'PAY', level: MonitoringLevel.info);
///
/// try {
///   await processPayment();
/// } catch (e, stack) {
///   await monitoring.recordError(e, stack, fatal: false);
/// }
///
/// final result = await monitoring.recordTransaction(
///   'checkout',
///   () => processCheckout(),
///   operation: 'http.post',
///   data: {'items': 3},
/// );
/// ```
abstract interface class AppMonitoring() {
  /// Whether at least one vendor is initialised and enabled.
  bool get isEnabled;

  /// Initialise all registered vendors. Call once during app bootstrap.
  Future<void> initialize();

  /// Dispose all registered vendors. Call on app teardown.
  Future<void> dispose();

  /// Set authenticated user context on all vendors.
  Future<void> setUserContext(String userId, {Map<String, dynamic>? extras});

  /// Clear user context on all vendors (call on logout).
  Future<void> clearUserContext();

  /// Log a structured message to all enabled vendors.
  void log(
    String message, {
    String? tag,
    MonitoringLevel level = MonitoringLevel.debug,
  });

  /// Record an error to all enabled vendors.
  ///
  /// Set [fatal] = true for crashes that should page on-call.
  /// [context] is extra key-value metadata attached to the report.
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  });

  /// Record a Flutter framework error to all enabled vendors.
  ///
  /// Called from the app's `FlutterError.onError`. Vendors implementing
  /// `FlutterAwareMonitoringVendor` get [details] as-is; the rest get
  /// [recordError] with `fatal: true`.
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Record a performance-traced transaction to all enabled vendors.
  ///
  /// The return value of [action] is forwarded to the caller regardless of
  /// vendor success or failure.
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  });

  /// Add a breadcrumb on all enabled vendors.
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    MonitoringLevel level = MonitoringLevel.debug,
  });
}
