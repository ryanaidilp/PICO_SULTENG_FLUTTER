import 'package:pico/router/app_router.dart';

/// Why an [InitializerResult] represents a failure.
///
/// Attached to [InitializerResult.failureReason] so callers (monitoring,
/// tests, phase-level logging) can distinguish *how* an initializer failed
/// without parsing error messages.
enum InitializerFailureReason() {
  /// The initializer's [Initializer.initialize] future did not complete
  /// within [Initializer.timeout]. The underlying future may still be
  /// running in the background — see the cancellation caveat on
  /// [Initializer.timeout].
  timeout,

  /// [Initializer.initialize] threw synchronously or asynchronously instead
  /// of returning an [InitializerResult.failure].
  threw,

  /// [Initializer.initialize] completed normally but returned
  /// `InitializerResult.failure(...)` itself.
  returnedFailure,
}

/// How critical an [Initializer]'s success is to the phase it runs in.
///
/// Consulted by the shared initializer runner (see
/// `apps/pico/lib/host/initializers/initializer_runner.dart`) to
/// decide whether a failure should abort the enclosing phase or be reported
/// and swallowed so the phase can proceed.
enum InitializerCriticality() {
  /// A failure aborts the entire launch phase.
  ///
  /// The phase's [InitializerResult] failure propagates outward — for
  /// pre-launch this reaches `HostAppWidget`'s error UI; for post-launch
  /// this should be rare (post-launch is meant to be non-blocking), but the
  /// option exists for a step that genuinely must not silently fail.
  required,

  /// A failure is reported to monitoring (non-fatal) but does not stop the
  /// phase — the remaining initializers still run and the phase completes
  /// as if this step had succeeded.
  ///
  /// Use this for steps whose absence degrades the app but does not break
  /// it (e.g. analytics, feature flags, deep-link routing).
  degradable,

  /// A failure is reported to monitoring (non-fatal) and otherwise ignored.
  ///
  /// Behaviorally identical to [degradable] in the shared runner (both
  /// swallow the failure and let the phase proceed); the distinction is for
  /// triage/observability — an [optional] step failing is expected to be
  /// lower priority to investigate than a [degradable] one. Use this for
  /// pure nice-to-haves (e.g. a prefetch that speeds up a later screen).
  optional,
}

/// The result of an initialization attempt.
///
/// Contains success status, optional error information, and the app router.
class InitializerResult {
  const new({
    required this.isInitializationSuccessful,
    this.error,
    this.router,
    this.failureReason,
  });

  /// Creates a successful result with an optional router.
  const new success({this.router})
    : isInitializationSuccessful = true,
      error = null,
      failureReason = null;

  /// Creates a failed result with the given error.
  ///
  /// [failureReason] defaults to [InitializerFailureReason.returnedFailure]
  /// since this constructor is normally used by an [Initializer.initialize]
  /// override
  /// that caught its own error and is reporting it as a normal return value
  /// (as opposed to letting it escape as a thrown exception, which the
  /// shared initializer runner classifies as [InitializerFailureReason.threw]
  /// itself).
  const new failure(
    this.error, {
    this.failureReason = InitializerFailureReason.returnedFailure,
  }) : isInitializationSuccessful = false,
       router = null;

  /// The error that occurred during initialization, if any.
  final Object? error;

  /// Whether the initialization completed successfully.
  final bool isInitializationSuccessful;

  /// The app router instance created during initialization.
  final AppRouter? router;

  /// Why this result is a failure. Always `null` when
  /// [isInitializationSuccessful] is `true`.
  final InitializerFailureReason? failureReason;

  /// Returns the router, throwing if router is null.
  ///
  /// Use this when you're certain the router was provided.
  AppRouter get requireRouter {
    assert(router != null, 'Router was not provided in initialization result');
    return router!;
  }
}

/// Base class for all app initializers.
///
/// Initializers handle setup and teardown of application components.
/// They follow a lifecycle pattern:
///
/// 1. [initialize] - Called during app startup
/// 2. [dispose] - Called during app shutdown
///
/// ## Creating an Initializer
///
/// ```dart
/// class AnalyticsInitializer extends Initializer {
///   @override
///   Future<InitializerResult> initialize() async {
///     try {
///       await Analytics.init();
///       return const InitializerResult.success();
///     } catch (e) {
///       return InitializerResult.failure(e);
///     }
///   }
///
///   @override
///   Future<bool> dispose() async {
///     await Analytics.shutdown();
///     return true;
///   }
/// }
/// ```
///
/// ## Pre-launch vs Post-launch
///
/// - Use `PreLaunchInitializer` for critical setup that must complete
///   before the UI is shown
/// - Use `PostLaunchInitializer` for non-critical setup that can happen
///   after the UI is visible
///
/// ## Parallel vs Sequential Execution
///
/// Override [canRunInParallel] to control execution behavior:
/// - `true` (default): Can run concurrently with other parallel initializers
/// - `false`: Must run sequentially, completing before the next starts
///
/// Sequential initializers run first (in order), then parallel ones together.
///
/// ## Criticality, timeouts, and failure handling
///
/// Every call to [initialize] made through the shared initializer runner
/// (`runInitializer` in `initializer_runner.dart`) is wrapped with a
/// [timeout] and reported through `AppMonitoring` on failure. [criticality]
/// decides what happens next:
///
/// - [InitializerCriticality.required]: the failure (or timeout) is
///   returned to the caller, which aborts the enclosing phase.
/// - [InitializerCriticality.degradable] / [InitializerCriticality.optional]:
///   the failure is reported non-fatally and swallowed — the phase proceeds
///   as if this step had succeeded.
///
/// ### Cancellation caveat
///
/// Dart cannot cancel an in-flight [Future]. When [initialize] exceeds
/// [timeout], the runner stops *waiting* on it and reports a
/// [InitializerFailureReason.timeout] failure, but the original call keeps
/// running in the background until it completes on its own. It may finish
/// (successfully or not) after [dispose] has already been called, or after
/// the process has moved on to the next phase. Implementations must be
/// designed to be safely abandoned mid-flight:
/// - Prefer idempotent writes over ones that assume single execution.
/// - Do not mutate shared mutable state after an `await` without guarding
///   against a second, still-in-flight invocation doing the same.
/// - Do not assume a timeout means side effects were rolled back — they
///   were not; only the *wait* was abandoned.
abstract class const Initializer() {
  /// Whether this initializer can run in parallel with others.
  ///
  /// Defaults to `true`. Override to return `false` if this initializer:
  /// - Has dependencies on other initializers
  /// - Modifies shared state that others read
  /// - Must complete before other initializers start
  ///
  /// Sequential initializers are executed first (in registration order),
  /// then all parallel initializers run concurrently.
  bool get canRunInParallel => true;

  /// How critical this initializer's success is to its enclosing phase.
  ///
  /// Defaults to [InitializerCriticality.required] — the conservative,
  /// historical behavior where any failure aborts the phase. This default
  /// suits pre-launch steps, which exist precisely because the app cannot
  /// safely run without them.
  ///
  /// Post-launch step implementations should almost always override this to
  /// [InitializerCriticality.degradable] (or [InitializerCriticality.optional]
  /// for pure nice-to-haves) — post-launch is non-blocking by design, and a
  /// failing step must never take the rest of the phase down with it. See
  /// `PostLaunchInitializer` for the concrete post-launch step classes.
  InitializerCriticality get criticality => InitializerCriticality.required;

  /// The maximum time this initializer is allowed to run before the shared
  /// runner treats it as failed with [InitializerFailureReason.timeout].
  ///
  /// Defaults to a deliberately generous 15 seconds. There is no per-step
  /// production timing data yet (a dedicated launch-tracing/observability
  /// gap tracks adding that), so an aggressive default would risk
  /// misclassifying slow-but-healthy steps (cold network, cold cache, first
  /// disk access) as failures — which is worse than a slow launch. Once
  /// step-level timing lands in the launch tracer, override this per step
  /// based on its observed P95 rather than lowering the shared default
  /// blindly.
  ///
  /// See the cancellation caveat in the class doc comment: exceeding this
  /// duration abandons the *wait*, not the underlying work.
  Duration get timeout => const Duration(seconds: 15);

  /// Initializes this component.
  ///
  /// Returns [InitializerResult] indicating success or failure.
  /// If initialization fails, the app startup may be aborted.
  Future<InitializerResult> initialize();

  /// Disposes resources held by this initializer.
  ///
  /// Returns `true` if disposal was successful, `false` otherwise.
  Future<bool> dispose();
}
