import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// No-op implementation of [AppMonitoring].
///
/// Same class name as the impl twin, so build_prepare swaps only the
/// package and its import, never a class name.
///
/// All methods are empty or pass-through. Swapped in for release builds
/// via `build_prepare.yaml` to strip all debug monitoring infrastructure.
/// Registered manually by `MonitoringImplPackageModule` (see
/// `injector.dart`), not via `@LazySingleton` -- this package no longer
/// runs injectable codegen.
class ConsentAwareMonitoring() implements AppMonitoring {
  @override
  bool get isEnabled => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setUserContext(
    String userId, {
    Map<String, dynamic>? extras,
  }) async {}

  @override
  Future<void> clearUserContext() async {}

  @override
  void log(
    String message, {
    String? tag,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {}

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  }) => action();

  @override
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {}
}
