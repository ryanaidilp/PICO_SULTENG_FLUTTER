import 'package:monitoring_api/src/monitoring/monitoring_level.dart';

/// Contract for a single monitoring vendor.
///
/// Each vendor brick (Crashlytics, Sentry, Grafana, New Relic) implements
/// this interface. The fanout orchestrator collects all registered vendors
/// and dispatches every call to all enabled ones.
///
/// The [vendorName] must be unique across all registered vendors — it is
/// also the string used with `@Named` in injectable DI registration.
abstract interface class AppMonitoringVendor() {
  /// Unique identifier for this vendor (e.g., 'crashlytics', 'sentry').
  String get vendorName;

  /// Whether this vendor is currently active and accepting telemetry.
  bool get isEnabled;

  /// Initialise this vendor. Called once during app bootstrap.
  Future<void> initialize();

  /// Release resources held by this vendor.
  Future<void> dispose();

  /// Set the authenticated user context for subsequent events.
  ///
  /// [extras] is a freeform map of additional user attributes
  /// (e.g., role, plan, country).
  Future<void> setUserContext(String userId, {Map<String, dynamic>? extras});

  /// Clear user context on logout.
  Future<void> clearUserContext();

  /// Log a structured message to this vendor.
  void log(
    String message, {
    String? tag,
    MonitoringLevel level = MonitoringLevel.debug,
  });

  /// Record an error or exception.
  ///
  /// [fatal] = true should trigger immediate alerting in the vendor.
  /// [context] carries additional key-value metadata for the report.
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  });

  /// Record a performance transaction and return its result.
  ///
  /// Vendors that support performance monitoring (Sentry, Grafana) should
  /// create a span around [action]. Others should call [action] directly.
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  });

  /// Add a breadcrumb (lightweight navigation/event marker).
  ///
  /// [category] is typically a module or screen name.
  /// [data] carries arbitrary structured context for the breadcrumb.
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    MonitoringLevel level = MonitoringLevel.debug,
  });
}
