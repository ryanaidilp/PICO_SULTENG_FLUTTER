import 'dart:async';

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_utilities/app_utilities.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:pico/host/initializers/initializer.dart';

/// Runs [initializer] with a timeout, a named trace span, and
/// criticality-aware failure handling.
///
/// This is the single shared execution path used by `PreLaunchInitializer`,
/// `PostLaunchInitializer`, and the Feature SDK sweep (via
/// [CallbackInitializer]) so all three treat failures identically instead of
/// each re-implementing their own try/catch/timeout/report logic:
///
/// 1. Wraps the call in a `'$phase:$label'` trace span via
///    [safeTraceProcessAsync] — a real OTLP span when monitoring is
///    wired and enabled (consent-gated), otherwise a plain call.
/// 2. Applies `initializer.timeout` via [Future.timeout]. See
///    [Initializer.timeout] for the cancellation caveat: this abandons the
///    *wait*, not the underlying work.
/// 3. Classifies the failure — [InitializerFailureReason.timeout] for a
///    timeout, [InitializerFailureReason.threw] for an escaped exception,
///    or whatever [InitializerFailureReason] a normally-returned
///    `InitializerResult.failure(...)` already carries (defaulting to
///    [InitializerFailureReason.returnedFailure]).
/// 4. Reports every failure through [monitoring] (when available) via
///    [AppMonitoring.recordError] — `fatal: true` for
///    [InitializerCriticality.required], `fatal: false` for
///    [InitializerCriticality.degradable]/[InitializerCriticality.optional].
/// 5. Decides what the caller sees:
///    - [InitializerCriticality.required]: the failure [InitializerResult]
///      is returned as-is, so the caller (a sequential/parallel loop) can
///      abort its phase exactly as it did before this helper existed.
///    - [InitializerCriticality.degradable] / [InitializerCriticality.optional]:
///      a synthetic [InitializerResult.success] is returned instead — the
///      failure was already reported in step 4, and the phase proceeds as
///      if this step had succeeded.
/// 6. When [tracker] is given, records the run as a [LaunchSpan] in
///    [launchPhase] with [mode]/[group] (the parallel batch id) and the
///    real outcome (`ok`/`failed`/`timeout`), even when step 5 swallows the
///    failure. Steps inside `initialize()` nest under it through
///    [traceLaunchStep].
Future<InitializerResult> runInitializer(
  Initializer initializer, {
  required String phase,
  required Log logger,
  AppMonitoring? monitoring,
  String? label,
  AppLaunchTracker? tracker,
  LaunchPhase? launchPhase,
  LaunchSpanMode mode = LaunchSpanMode.sequential,
  String? group,
}) async {
  final name = label ?? initializer.runtimeType.toString();
  final spanKey = '$phase:$name';

  Future<InitializerResult> run() =>
      initializer.initialize().timeout(initializer.timeout);

  InitializerResult result;
  try {
    result = await safeTraceProcessAsync<InitializerResult>(
      key: spanKey,
      monitoring: monitoring,
      block: tracker == null
          ? run
          : () => tracker.traceSpan(
              name,
              run,
              phase: launchPhase,
              mode: mode,
              group: group,
              statusOf: (r) => r.isInitializationSuccessful
                  ? LaunchSpanStatus.ok
                  : LaunchSpanStatus.failed,
            ),
    );
  } on TimeoutException catch (error, stackTrace) {
    logger.consoleLazy(
      () => '[$spanKey] timed out after ${initializer.timeout}',
      type: LogType.warning,
    );
    await _report(
      monitoring,
      spanKey,
      initializer.criticality,
      error,
      stackTrace,
    );
    result = InitializerResult.failure(
      error,
      failureReason: InitializerFailureReason.timeout,
    );
  } catch (error, stackTrace) {
    logger.consoleLazy(
      () => '[$spanKey] threw: $error',
      error: error,
      stackTrace: stackTrace,
      type: LogType.error,
    );
    await _report(
      monitoring,
      spanKey,
      initializer.criticality,
      error,
      stackTrace,
    );
    result = InitializerResult.failure(
      error,
      failureReason: InitializerFailureReason.threw,
    );
  }

  if (result.isInitializationSuccessful) return result;

  // A normally-returned failure (as opposed to a thrown/timed-out one,
  // already logged/reported above) hasn't been logged/reported yet.
  if (result.failureReason != InitializerFailureReason.timeout &&
      result.failureReason != InitializerFailureReason.threw) {
    logger.consoleLazy(
      () => '[$spanKey] returned failure: ${result.error}',
      type: LogType.warning,
    );
    await _report(
      monitoring,
      spanKey,
      initializer.criticality,
      result.error ?? StateError('$spanKey returned a failure result'),
      StackTrace.current,
    );
  }

  if (initializer.criticality == InitializerCriticality.required) {
    return result;
  }

  // degradable / optional: already reported above, let the phase proceed.
  return const InitializerResult.success();
}

Future<void> _report(
  AppMonitoring? monitoring,
  String spanKey,
  InitializerCriticality criticality,
  Object error,
  StackTrace stackTrace,
) async {
  if (monitoring == null) return;
  await monitoring.recordError(
    error,
    stackTrace,
    fatal: criticality == InitializerCriticality.required,
    context: {'initializer': spanKey, 'criticality': criticality.name},
  );
}

/// Adapts an arbitrary async callback into an [Initializer] so callers that
/// aren't already shaped like one can still go through [runInitializer].
///
/// Used by the Feature SDK sweep in `PreLaunchInitializer`, where each SDK's
/// bare `registerRoutes`/`initialize` call is wrapped in a
/// [CallbackInitializer] so a single misbehaving SDK gets the same
/// timeout/trace/report treatment as a first-class [Initializer] — and, at
/// the default [InitializerCriticality.degradable], never aborts the launch
/// of the remaining SDKs.
class CallbackInitializer({
  /// The work to run. Wrap synchronous work in `Future(() => ...)` at the
  /// call site so it still goes through the same timeout/trace machinery.
  required final Future<void> Function() action,
  @override
  final InitializerCriticality criticality = InitializerCriticality.degradable,
  @override final Duration timeout = const Duration(seconds: 15),
}) extends Initializer {
  @override
  Future<InitializerResult> initialize() async {
    await action();
    return const InitializerResult.success();
  }

  @override
  Future<bool> dispose() async => true;
}
