// Bricks inject imports into the archipelago:post_launch_imports region, which sits after router/ and so sorts out of order (`unnecessary_ignore` covers the empty or sorted case).
// ignore_for_file: directives_ordering, unnecessary_ignore

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_utilities/app_utilities.dart';

import 'package:flutter/widgets.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/host/initializers/initializer.dart';
import 'package:pico/host/initializers/initializer_runner.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

// archipelago:post_launch_imports:start
// archipelago:post_launch_imports:end

/// Initializes components after the app UI has launched.
///
/// Post-launch initializers are for tasks that can happen after the UI is
/// visible, such as:
/// - Remote config fetching
/// - Non-critical data prefetching
/// - Feature flag updates
/// - Background sync setup
/// - Analytics initialization
///
/// ## Execution Order
///

/// 1. Sequential initializers (`canRunInParallel = false`) run first, in order
/// 2. Parallel initializers (`canRunInParallel = true`) run concurrently after
///
/// Every initializer (steps 1–2) runs through the shared `runInitializer`
/// helper (see `initializer_runner.dart`), which applies a timeout and
/// reports failures through `AppMonitoring`. Post-launch step
/// implementations should override [Initializer.criticality] to
/// [InitializerCriticality.degradable] (the base default is
/// [InitializerCriticality.required]) — post-launch is non-blocking by
/// design, so one step failing is reported but never stops the others or
/// fails the phase. Wrap a new post-launch step the same way as the existing
/// steps in this file: a small `Initializer` subclass whose `initialize()`
/// catches its own errors and returns `InitializerResult.failure(e)` rather
/// than letting them propagate.
///
/// These are called from `HostAppWidget` after pre-launch initialization
/// completes and the first frame is rendered.
class PostLaunchInitializer._(final List<Initializer> _initializers)
    extends Initializer {
  /// Creates a [PostLaunchInitializer] with default initializers.
  ///
  /// Parameters are kept for API contract -- feature initializers will use them.
  factory create({
    // Kept for API contract — feature initializers will use context.
    // ignore: avoid_unused_constructor_parameters
    required BuildContext context,
    // Kept for API contract — feature initializers will use router.
    // ignore: avoid_unused_constructor_parameters
    required AppRouter router,
  }) => PostLaunchInitializer._([
    // TODO(archipelago): Add more post-launch initializers here as needed.
    // archipelago:post_launch_initializers:start
    // archipelago:post_launch_initializers:end
    _UiKitAssetPreloadInitializer(context),
  ]);

  /// Creates a [PostLaunchInitializer] with an explicit initializer list,
  /// bypassing the default (context/router-driven) list in
  /// [PostLaunchInitializer.create].
  ///
  /// For tests only — lets a test drive [initialize]/[dispose] against
  /// controlled [Initializer] doubles.
  @visibleForTesting
  factory forTesting(List<Initializer> initializers) =>
      PostLaunchInitializer._(initializers);

  static const String _tag = 'PostLaunchInitializer';

  /// [LaunchSpan.group] of this phase's parallel batch.
  static const String _parallelGroup = 'post_launch.parallel';

  /// Wall-clock budget for the whole post-launch phase.
  ///
  /// Larger than `PreLaunchInitializer`'s budget since post-launch is
  /// non-blocking by design — exceeding it only emits a distinguishable
  /// event, it never delays or fails anything user-visible.
  static const Duration _phaseBudget = Duration(seconds: 10);

  final Log _logger = getIt<Log>();

  /// Null when monitoring is not installed or cannot be built, so reporting
  /// a failure can never itself fail the phase.
  AppMonitoring? get _monitoring {
    try {
      return getIt.isRegistered<AppMonitoring>()
          ? getIt<AppMonitoring>()
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Null when no launch tracker is registered (e.g. tests); spans are then
  /// not recorded.
  AppLaunchTracker? get _tracker =>
      getIt.isRegistered<AppLaunchTracker>() ? getIt<AppLaunchTracker>() : null;

  @override
  bool get canRunInParallel => false;

  @override
  Future<InitializerResult> initialize() async {
    final stopwatch = Stopwatch()..start();
    final result = await _runPhase();
    stopwatch.stop();
    _checkPhaseBudget(stopwatch.elapsed);
    return result;
  }

  Future<InitializerResult> _runPhase() async {
    final sequential = _initializers.where((i) => !i.canRunInParallel).toList();
    final parallel = _initializers.where((i) => i.canRunInParallel).toList();

    // Run sequential initializers first, in order.
    if (sequential.isNotEmpty) {
      _logger.consoleLazy(
        () =>
            '[$_tag] initializing ${sequential.length} sequential initializers',
      );
      for (final initializer in sequential) {
        _logger.consoleLazy(() => '[$_tag] initializing $initializer');
        final result = await runInitializer(
          initializer,
          phase: _tag,
          logger: _logger,
          monitoring: _monitoring,
          tracker: _tracker,
          launchPhase: LaunchPhase.postLaunch,
        );
        // Reachable only if a post-launch step overrides criticality back
        // to `required` — a default (degradable) step never returns a
        // failure here, since runInitializer already swallowed it.
        if (!result.isInitializationSuccessful) {
          return result;
        }
      }
    }

    // Run parallel initializers concurrently. runInitializer already
    // absorbs failures per [Initializer.criticality], so a
    // throwing/timing-out/failing degradable initializer is reported but
    // never short-circuits the others.
    if (parallel.isNotEmpty) {
      _logger.consoleLazy(
        () => '[$_tag] initializing ${parallel.length} parallel initializers',
      );
      await Future.wait(
        parallel.map(
          (initializer) => runInitializer(
            initializer,
            phase: _tag,
            logger: _logger,
            monitoring: _monitoring,
            tracker: _tracker,
            launchPhase: LaunchPhase.postLaunch,
            mode: LaunchSpanMode.parallel,
            group: _parallelGroup,
          ),
        ),
      );
    }

    _logger.consoleLazy(() => '[$_tag] initialized');
    return const InitializerResult.success();
  }

  void _checkPhaseBudget(Duration elapsed) {
    if (elapsed <= _phaseBudget) return;

    _logger.consoleLazy(
      () =>
          '[$_tag] phase budget exceeded: '
          '${elapsed.inMilliseconds}ms > ${_phaseBudget.inMilliseconds}ms',
      type: LogType.warning,
    );
    _monitoring?.breadcrumb(
      'post_launch_phase_budget_exceeded',
      category: 'launch',
      level: MonitoringLevel.warning,
      data: {
        'elapsed_ms': elapsed.inMilliseconds,
        'budget_ms': _phaseBudget.inMilliseconds,
      },
    );
  }

  @override
  Future<bool> dispose() async {
    final sequential = _initializers.where((i) => !i.canRunInParallel).toList();
    final parallel = _initializers.where((i) => i.canRunInParallel).toList();

    // Dispose parallel initializers first (reverse of initialization order).
    if (parallel.isNotEmpty) {
      _logger.consoleLazy(
        () => '[$_tag] disposing ${parallel.length} parallel initializers',
      );
      final results = await Future.wait(
        parallel.map((initializer) {
          _logger.consoleLazy(() => '[$_tag] disposing $initializer');
          return initializer.dispose();
        }),
      );
      if (results.any((result) => !result)) {
        return false;
      }
    }

    // Dispose sequential initializers in reverse order.
    for (final initializer in sequential.reversed) {
      _logger.consoleLazy(() => '[$_tag] disposing $initializer');
      final result = await initializer.dispose();
      if (!result) {
        return result;
      }
    }

    _logger.consoleLazy(() => '[$_tag] disposed');
    return true;
  }
}

/// Precaches the UI kit's declared critical assets (icons, logos, Lottie
/// files) once a [BuildContext] is available.
///
/// Needs a [BuildContext] (`precacheImage`/SVG decode), so this runs in
/// post-launch rather than pre-launch, which has no widget tree yet.
class _UiKitAssetPreloadInitializer(final BuildContext _context)
    extends Initializer {
  @override
  bool get canRunInParallel => true;

  @override
  InitializerCriticality get criticality => InitializerCriticality.degradable;

  @override
  Future<InitializerResult> initialize() async {
    try {
      await PicoUiKitInitializer.initializeAssets(_context);
      return const InitializerResult.success();
    } catch (e) {
      return InitializerResult.failure(e);
    }
  }

  @override
  Future<bool> dispose() async => true;
}
