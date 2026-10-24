import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// Wraps an async [block] with an OTLP span via [AppMonitoring.recordTransaction]
/// if monitoring is available, otherwise executes the block directly.
///
/// Lookup is done via [AppMonitoring] from GetIt if registered. This function
/// does NOT hard-depend on any concrete monitoring impl — only the
/// [AppMonitoring] contract from `monitoring_api`.
///
/// ```dart
/// await safeTraceProcessAsync(
///   key: 'initializeRouter',
///   block: () => router.initialize(),
/// );
/// ```
Future<T> safeTraceProcessAsync<T>({
  required String key,
  required FutureOr<T> Function() block,
  AppMonitoring? monitoring,
}) async {
  if (monitoring != null && monitoring.isEnabled) {
    return await monitoring.recordTransaction(key, () async => await block());
  }
  return await block();
}

/// Wraps an async [block] and prints its duration to the debug console.
///
/// ```dart
/// final result = await traceAsync(
///   key: 'fetchUserProfile',
///   block: () => repo.getProfile(userId),
/// );
/// ```
///
/// Outputs: `Trace::SysLog::fetchUserProfile::42::ms`
FutureOr<T> traceAsync<T>({
  required String key,
  required FutureOr<T> Function() block,
}) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  final result = await block();
  final duration = DateTime.now().millisecondsSinceEpoch - startTime;
  debugPrint('Trace::SysLog::$key::$duration::ms');
  return result;
}

/// Wraps a synchronous [block] and prints its duration to the debug console.
///
/// Use [traceAsync] for `Future`-returning blocks.
///
/// Outputs: `Trace::SysLog::buildWidgetTree::3::ms`
T traceSync<T>({required String key, required T Function() block}) {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  final result = block();
  final duration = DateTime.now().millisecondsSinceEpoch - startTime;
  debugPrint('Trace::SysLog::$key::$duration::ms');
  return result;
}
