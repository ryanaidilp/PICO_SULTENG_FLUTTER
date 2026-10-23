// Bricks inject imports into the archipelago:pre_launch_imports region, which sits after router/ and so sorts out of order (`unnecessary_ignore` covers the empty or sorted case).
// ignore_for_file: directives_ordering, unnecessary_ignore

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_utilities/app_utilities.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:router_registry/router_registry.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/host/initializers/initializer.dart';
import 'package:pico/host/initializers/initializer_runner.dart';
import 'package:pico/router/app_router.dart';

import 'dart:async';

import 'package:pico_ui_kit/pico_ui_kit.dart';

// archipelago:pre_launch_imports:start
// archipelago:pre_launch_imports:end

/// Controls the pre-launch initialization lifecycle of the application.
///
/// Pre-launch initialization handles critical setup that must complete before
/// the UI is shown. This blocks the app launch.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   runApp(
///     HostAppWidget(
///       initializerController: PreLaunchInitializerController.create(),
///       builder: (context, result) => const MyApp(),
///     ),
///   );
/// }
/// ```
class const PreLaunchInitializerController._(
  final PreLaunchInitializer _preLaunchInitializer,
) {
  /// Factory constructor with default pre-launch initializer.
  ///
  /// [additional] is forwarded to [PreLaunchInitializer.create] — see its
  /// doc comment for how brick-owned and app-owned initializers combine.
  factory create({List<Initializer> additional = const []}) =>
      PreLaunchInitializerController._(
        PreLaunchInitializer.create(additional: additional),
      );

  /// Runs pre-launch initialization.
  ///
  /// All pre-launch initializers must complete before the app UI is shown.
  Future<InitializerResult> initialize() => _preLaunchInitializer.initialize();

  /// Disposes all pre-launch initializers.
  Future<void> dispose() => _preLaunchInitializer.dispose();
}

/// Initializes critical components before the app UI is launched.
///
/// Pre-launch initializers are for tasks that MUST complete before the UI
/// is shown, such as:
/// - Feature route registration (from each `FeatureManifest`)
/// - Critical SDK initialization
/// - Database initialization
/// - Authentication state restoration
///
/// ## Execution Order
///
/// 1. Sequential initializers (`canRunInParallel == false`) run first, in
///    registration order.
/// 2. Parallel initializers (`canRunInParallel == true`) then run together.
/// 3. The manifest sweep runs last: seal [FeatureSDKRegistry], take its
///    enabled manifests, call `registerRoutes()` on each, lock
///    [RouteRegistry], then call `initialize()` on each. Feature SDKs are
///    lazy and are not built here, except the few that are their own
///    manifest (`FeatureSDK`).
/// 4. Create [AppRouter] with the registered routes and return the final
///    [InitializerResult].
///
/// Steps 1–2 draw from the combined initializer list (see below); step 3
/// always runs regardless of that list's contents, since features register
/// their manifests independently of it.
///
/// ## Brick-owned vs app-owned initializers
///
/// The combined list passed to steps 1–2 is built from two regions, in this
/// order:
///
/// 1. **Brick-owned** — entries inside the
///    `// archipelago:pre_launch_initializers:start/end` marker pair below.
///    Bricks' post-gen hooks inject entries here; never hand-edit this
///    region (see `.claude/skills/generator-markers/SKILL.md`).
/// 2. **App-owned** — the [Initializer]s passed via [PreLaunchInitializer.create]'s `additional`
///    parameter, appended after the brick-owned entries in the order given.
///    This is for initializers the app itself supplies at the `main.dart`/
///    `bootstrap.dart` call site, e.g. steps specific to one flavor.
///
/// The two regions are concatenated (brick-owned first) into a single list
/// *before* the sequential/parallel split runs, so a sequential entry from
/// either region is ordered relative to the other purely by its position in
/// the combined list — origin (marker vs `additional`) does not create a
/// separate execution lane. This keeps the two composition mechanisms from
/// competing for the same slot while remaining fully deterministic.
///
/// ## Criticality, timeouts, and failure handling
///
/// Every initializer in the combined list — regardless of whether it came
/// from the marker region or `additional` — is executed through the shared
/// `runInitializer` helper (see `initializer_runner.dart`), so timeouts and
/// [Initializer.criticality] apply uniformly. Individual manifest
/// `registerRoutes`/`initialize` calls go through the same helper via
/// [CallbackInitializer] at [InitializerCriticality.degradable] — a single
/// misbehaving feature is reported but never aborts the launch of the others.
class PreLaunchInitializer._(final List<Initializer> _initializers)
    extends Initializer {
  /// Creates a [PreLaunchInitializer].
  ///
  /// [additional] lets the app contribute its own pre-launch steps without
  /// touching the marker-managed (brick-owned) region — see the class doc
  /// comment for how the two regions combine.
  factory create({List<Initializer> additional = const []}) =>
      PreLaunchInitializer._([
        // archipelago:pre_launch_initializers:start
        // archipelago:pre_launch_initializers:end
        ...additional,
        _FontPreloadInitializer(),
      ]);

  static const String _tag = 'PreLaunchInitializer';

  /// [LaunchSpan.group] of this phase's parallel batch.
  static const String _parallelGroup = 'pre_launch.parallel';

  /// Wall-clock budget for the whole pre-launch phase (steps 1–3 combined).
  ///
  /// Deliberately generous — pre-launch has no per-step production timing
  /// data yet (see the `Initializer.timeout` doc comment for the same
  /// caveat). Exceeding this does not abort the phase; it only emits a
  /// distinguishable event (log + launch-tracker step + monitoring
  /// breadcrumb) so slow launches are visible without being fatal.
  static const Duration _phaseBudget = Duration(seconds: 5);

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
          launchPhase: LaunchPhase.preLaunch,
        );
        if (!result.isInitializationSuccessful) {
          return result;
        }
      }
    }

    // Run parallel initializers concurrently.
    if (parallel.isNotEmpty) {
      _logger.consoleLazy(
        () => '[$_tag] initializing ${parallel.length} parallel initializers',
      );
      final results = await Future.wait(
        parallel.map(
          (initializer) => runInitializer(
            initializer,
            phase: _tag,
            logger: _logger,
            monitoring: _monitoring,
            tracker: _tracker,
            launchPhase: LaunchPhase.preLaunch,
            mode: LaunchSpanMode.parallel,
            group: _parallelGroup,
          ),
        ),
      );

      for (final result in results) {
        if (!result.isInitializationSuccessful) {
          return result;
        }
      }
    }

    // Discover feature manifests. Sealing first makes a manifest that joins
    // the registry after this snapshot (so it would never get
    // registerRoutes/initialize) fail loudly in debug builds. Disabled
    // features are skipped per the FeatureManifest.isEnabled contract.
    _logger.consoleLazy(() => '[$_tag] discovering feature manifests');
    final registry = FeatureSDKRegistry.instance..seal();
    final manifests = registry.enabledManifests;

    // Register routes from every manifest. Each is wrapped in a degradable
    // CallbackInitializer so one manifest throwing is reported but never
    // blocks the others or aborts the phase.
    final routeRegistry = getIt<RouteRegistry>();
    for (final manifest in manifests) {
      _logger.consoleLazy(
        () => '[$_tag] registering routes for ${manifest.runtimeType}',
      );
      await runInitializer(
        CallbackInitializer(
          action: () async => manifest.registerRoutes(routeRegistry),
        ),
        phase: _tag,
        logger: _logger,
        monitoring: _monitoring,
        tracker: _tracker,
        launchPhase: LaunchPhase.preLaunch,
        label: '${manifest.runtimeType}.registerRoutes',
      );
    }
    routeRegistry.lock();

    // Initialize every manifest. Same degradable wrapping as above.
    for (final manifest in manifests) {
      _logger.consoleLazy(() => '[$_tag] initializing ${manifest.runtimeType}');
      await runInitializer(
        CallbackInitializer(action: manifest.initialize),
        phase: _tag,
        logger: _logger,
        monitoring: _monitoring,
        tracker: _tracker,
        launchPhase: LaunchPhase.preLaunch,
        label: '${manifest.runtimeType}.initialize',
      );
    }

    _logger.consoleLazy(() => '[$_tag] initialized');

    // Return with the router that was created during initialization.
    return InitializerResult.success(router: AppRouter(routeRegistry));
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
      'pre_launch_phase_budget_exceeded',
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

/// Starts warming the UI kit's Google Fonts as early as pre-launch, without
/// blocking it.
///
/// `google_fonts` fetches these over the network and caches them after --
/// this must never block or fail pre-launch, so the fetch is
/// fire-and-forget: a failure (offline, DNS, timeout) is logged and
/// swallowed. Text already on screen using these families simply reflows
/// once the fetch resolves, same as any other deferred font load.
class _FontPreloadInitializer() extends Initializer {
  @override
  bool get canRunInParallel => true;

  @override
  Future<InitializerResult> initialize() async {
    unawaited(
      PicoFontInitializer.initialize().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        getIt<Log>().consoleLazy(
          () =>
              '[_FontPreloadInitializer] font fetch failed: '
              '$error\n$stackTrace',
          type: LogType.warning,
        );
      }),
    );
    return const InitializerResult.success();
  }

  @override
  Future<bool> dispose() async => true;
}
