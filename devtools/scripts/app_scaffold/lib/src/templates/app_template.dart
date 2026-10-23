/// Generates the app.dart file with MaterialApp.router.
String appTemplate({
  required String appName,
  required String appClassName,
  required String appTitle,
  required String uiKitPackageName,
  required String themeClassName,
}) =>
    '''
import 'package:$uiKitPackageName/$uiKitPackageName.dart';
import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:$appName/benchmark.dart';
import 'package:$appName/router/app_router.dart';

class $appClassName extends StatelessWidget {
  const $appClassName({required this.router, required this.benchmark, super.key});

  final AppRouter router;
  final StartupBenchmark benchmark;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: '$appTitle',
    theme: $themeClassName.light(),
    darkTheme: $themeClassName.dark(),
    routerConfig: router.config(
      deepLinkBuilder: (_) => DeepLink.path(router.initialPath),
    ),
  );
}
''';

/// Generates the benchmark.dart file.
String benchmarkTemplate() => r'''
import 'package:flutter/foundation.dart';

class StartupBenchmarkSnapshot {
  const StartupBenchmarkSnapshot({
    required this.mode,
    required this.firstFrameMs,
    required this.preLaunchMs,
    required this.postLaunchMs,
    required this.totalStartupWorkMs,
  });

  final String mode;
  final int firstFrameMs;
  final int preLaunchMs;
  final int postLaunchMs;
  final int totalStartupWorkMs;

  StartupBenchmarkSnapshot copyWith({
    String? mode,
    int? firstFrameMs,
    int? preLaunchMs,
    int? postLaunchMs,
    int? totalStartupWorkMs,
  }) => StartupBenchmarkSnapshot(
    mode: mode ?? this.mode,
    firstFrameMs: firstFrameMs ?? this.firstFrameMs,
    preLaunchMs: preLaunchMs ?? this.preLaunchMs,
    postLaunchMs: postLaunchMs ?? this.postLaunchMs,
    totalStartupWorkMs: totalStartupWorkMs ?? this.totalStartupWorkMs,
  );
}

class StartupBenchmark extends ValueNotifier<StartupBenchmarkSnapshot> {
  StartupBenchmark({required String mode})
    : _appStopwatch = Stopwatch(),
      _postLaunchStopwatch = Stopwatch(),
      super(
        StartupBenchmarkSnapshot(
          mode: mode,
          firstFrameMs: 0,
          preLaunchMs: 0,
          postLaunchMs: 0,
          totalStartupWorkMs: 0,
        ),
      );

  final Stopwatch _appStopwatch;
  final Stopwatch _postLaunchStopwatch;

  void startApp() {
    if (!_appStopwatch.isRunning) {
      _appStopwatch.start();
    }
  }

  void markPreLaunchCompleted() {
    value = value.copyWith(preLaunchMs: _appStopwatch.elapsedMilliseconds);
  }

  void markFirstFrameRendered() {
    value = value.copyWith(firstFrameMs: _appStopwatch.elapsedMilliseconds);
  }

  void startPostLaunch() {
    if (!_postLaunchStopwatch.isRunning) {
      _postLaunchStopwatch.start();
    }
  }

  void finishPostLaunch() {
    if (_postLaunchStopwatch.isRunning) {
      _postLaunchStopwatch.stop();
    }

    value = value.copyWith(
      postLaunchMs: _postLaunchStopwatch.elapsedMilliseconds,
      totalStartupWorkMs:
          value.preLaunchMs + _postLaunchStopwatch.elapsedMilliseconds,
    );
  }

  void printSummary() {
    debugPrint('===== Startup Benchmark =====');
    debugPrint('Mode: ${value.mode}');
    debugPrint('First frame: ${value.firstFrameMs} ms');
    debugPrint('PreLaunch: ${value.preLaunchMs} ms');
    debugPrint('PostLaunch: ${value.postLaunchMs} ms');
    debugPrint('Total startup work: ${value.totalStartupWorkMs} ms');
    debugPrint('=============================');
  }
}
''';

/// Generates the router/app_router.dart file.
String routerTemplate({required String appName}) => '''
import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:router_registry/router_registry.dart';

part 'app_router.gr.dart';

/// Main app router that combines routes from all feature manifests.
///
/// Routes are registered dynamically via the [RouteRegistry] during pre-launch
/// initialization. Each feature manifest registers its routes before the app
/// starts.
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter(this._registry);

  final RouteRegistry _registry;

  @override
  List<AutoRoute> get routes => [..._registry.routes];

  /// The first claim that resolves among the features' initial-path claims
  /// (see `InitialPathProvider`).
  String get initialPath => FeatureSDKRegistry.instance.resolveInitialPath();
}
''';

/// Generates the host/host_app_widget.dart file.
String hostAppWidgetTemplate({required String appName}) =>
    '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:$appName/benchmark.dart';
import 'package:$appName/host/initializers/initializer.dart';
import 'package:$appName/host/initializers/post_launch_initializer.dart';
import 'package:$appName/host/initializers/pre_launch_initializer.dart';

/// Builder function for [HostAppWidget].
typedef HostAppWidgetBuilder =
    Widget Function(BuildContext context, InitializerResult result);

/// Builder function for error widget in [HostAppWidget].
typedef HostAppErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

/// The root widget that manages app initialization lifecycle.
///
/// Orchestrates two-phase initialization:
/// 1. **Pre-launch**: Blocks UI rendering
/// 2. **Post-launch**: Runs after first frame
class HostAppWidget extends StatefulWidget {
  const HostAppWidget({
    required this.builder,
    required this.initializerController,
    required this.benchmark,
    this.postInitializeCallback,
    this.loadingWidget,
    this.errorBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionBuilder,
    super.key,
  });

  final StartupBenchmark benchmark;
  final HostAppWidgetBuilder builder;
  final VoidCallback? postInitializeCallback;
  final PreLaunchInitializerController initializerController;
  final Widget? loadingWidget;
  final HostAppErrorBuilder? errorBuilder;
  final Duration transitionDuration;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  @override
  State<HostAppWidget> createState() => _HostAppWidgetState();
}

class _HostAppWidgetState extends State<HostAppWidget> {
  final Completer<InitializerResult> _completer =
      Completer<InitializerResult>();
  PostLaunchInitializer? _postLaunchInitializer;

  @override
  Widget build(BuildContext context) => FutureBuilder<InitializerResult>(
    future: _completer.future,
    builder: (_, snapshot) {
      final Widget child;

      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          child = KeyedSubtree(
            key: const ValueKey('error'),
            child: _buildErrorWidget(
              context,
              snapshot.error!,
              snapshot.stackTrace,
            ),
          );
        } else {
          child = KeyedSubtree(
            key: const ValueKey('app'),
            child: widget.builder(context, snapshot.requireData),
          );
        }
      } else {
        child = KeyedSubtree(
          key: const ValueKey('loading'),
          child: _buildLoadingWidget(),
        );
      }

      return AnimatedSwitcher(
        duration: widget.transitionDuration,
        transitionBuilder: widget.transitionBuilder ?? _defaultTransition,
        child: child,
      );
    },
  );

  Widget _buildLoadingWidget() =>
      widget.loadingWidget ?? const Center(child: CircularProgressIndicator());

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'There is something wrong: \$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _defaultTransition(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);

  @override
  void initState() {
    super.initState();

    widget.initializerController
        .initialize()
        .then((result) async {
          if (mounted) {
            widget.benchmark.markPreLaunchCompleted();
            _completer.complete(result);

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                widget.benchmark.markFirstFrameRendered();

                _postLaunchInitializer = PostLaunchInitializer.create(
                  context: context,
                  router: result.requireRouter,
                );
                widget.benchmark.startPostLaunch();

                await _postLaunchInitializer?.initialize();

                widget.benchmark.finishPostLaunch();
                widget.benchmark.printSummary();

                if (mounted) {
                  widget.postInitializeCallback?.call();
                }
              }
            });
          }
        })
        .catchError((Object error, StackTrace stackTrace) async {
          if (mounted) {
            _completer.completeError(error, stackTrace);
          }
        });
  }

  @override
  void dispose() {
    widget.initializerController.dispose();
    _postLaunchInitializer?.dispose();
    super.dispose();
  }
}
''';

/// Generates the host/initializers/initializer.dart file.
String initializerTemplate({required String appName}) =>
    '''
import 'package:$appName/router/app_router.dart';

/// The result of an initialization attempt.
class InitializerResult {
  const InitializerResult({
    required this.isInitializationSuccessful,
    this.error,
    this.router,
  });

  const InitializerResult.success({this.router})
    : isInitializationSuccessful = true,
      error = null;

  const InitializerResult.failure(this.error)
    : isInitializationSuccessful = false,
      router = null;

  final Object? error;
  final bool isInitializationSuccessful;
  final AppRouter? router;

  AppRouter get requireRouter {
    assert(router != null, 'Router was not provided in initialization result');
    return router!;
  }
}

/// Base class for all app initializers.
abstract class Initializer {
  const Initializer();

  bool get canRunInParallel => true;

  Future<InitializerResult> initialize();

  Future<bool> dispose();
}
''';

/// Generates the host/initializers/pre_launch_initializer.dart file.
String preLaunchInitializerTemplate({required String appName}) =>
    '''
import 'package:app_utilities/app_utilities.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:router_registry/router_registry.dart';
import 'package:$appName/di/injector.dart';
import 'package:$appName/host/initializers/initializer.dart';
import 'package:$appName/router/app_router.dart';

/// Controls the pre-launch initialization lifecycle.
class PreLaunchInitializerController {
  const PreLaunchInitializerController._(this._preLaunchInitializer);

  factory PreLaunchInitializerController.create() =>
      PreLaunchInitializerController._(PreLaunchInitializer.create());

  final PreLaunchInitializer _preLaunchInitializer;

  Future<InitializerResult> initialize() => _preLaunchInitializer.initialize();

  Future<void> dispose() => _preLaunchInitializer.dispose();
}

/// Initializes critical components before the app UI is launched.
class PreLaunchInitializer extends Initializer {
  PreLaunchInitializer._(this._initializers);

  factory PreLaunchInitializer.create() => PreLaunchInitializer._([]);

  static const String _tag = 'PreLaunchInitializer';

  final List<Initializer> _initializers;

  final Log _logger = getIt<Log>();

  @override
  bool get canRunInParallel => false;

  @override
  Future<InitializerResult> initialize() async {
    final sequential = _initializers.where((i) => !i.canRunInParallel).toList();
    final parallel = _initializers.where((i) => i.canRunInParallel).toList();

    if (sequential.isNotEmpty) {
      _logger.consoleLazy(
        () =>
            '[\$_tag] initializing \${sequential.length} sequential initializers',
      );
      for (final initializer in sequential) {
        _logger.consoleLazy(() => '[\$_tag] initializing \$initializer');
        final result = await initializer.initialize();
        if (!result.isInitializationSuccessful) {
          return result;
        }
      }
    }

    if (parallel.isNotEmpty) {
      _logger.consoleLazy(
        () => '[\$_tag] initializing \${parallel.length} parallel initializers',
      );
      final results = await Future.wait(
        parallel.map((initializer) async {
          _logger.consoleLazy(() => '[\$_tag] initializing \$initializer');
          return initializer.initialize();
        }),
      );

      for (final result in results) {
        if (!result.isInitializationSuccessful) {
          return result;
        }
      }
    }

    // Seal first so a late manifest fails loudly in debug builds; disabled
    // features are skipped per the FeatureManifest.isEnabled contract.
    _logger.consoleLazy(() => '[\$_tag] discovering feature manifests');
    final registry = FeatureSDKRegistry.instance..seal();
    final manifests = registry.enabledManifests;

    final routeRegistry = getIt<RouteRegistry>();
    for (final manifest in manifests) {
      _logger.consoleLazy(
        () => '[\$_tag] registering routes for \${manifest.runtimeType}',
      );
      manifest.registerRoutes(routeRegistry);
    }
    routeRegistry.lock();

    for (final manifest in manifests) {
      _logger.consoleLazy(() => '[\$_tag] initializing \${manifest.runtimeType}');
      await manifest.initialize();
    }

    _logger.consoleLazy(() => '[\$_tag] initialized');

    return InitializerResult.success(router: AppRouter(routeRegistry));
  }

  @override
  Future<bool> dispose() async {
    final sequential = _initializers.where((i) => !i.canRunInParallel).toList();
    final parallel = _initializers.where((i) => i.canRunInParallel).toList();

    if (parallel.isNotEmpty) {
      _logger.consoleLazy(
        () => '[\$_tag] disposing \${parallel.length} parallel initializers',
      );
      final results = await Future.wait(
        parallel.map((initializer) {
          _logger.consoleLazy(() => '[\$_tag] disposing \$initializer');
          return initializer.dispose();
        }),
      );
      if (results.any((result) => !result)) {
        return false;
      }
    }

    for (final initializer in sequential.reversed) {
      _logger.consoleLazy(() => '[\$_tag] disposing \$initializer');
      final result = await initializer.dispose();
      if (!result) {
        return result;
      }
    }

    _logger.consoleLazy(() => '[\$_tag] disposed');
    return true;
  }
}
''';

/// Generates the host/initializers/post_launch_initializer.dart file.
String postLaunchInitializerTemplate({required String appName}) =>
    '''
import 'package:flutter/widgets.dart';
import 'package:$appName/host/initializers/initializer.dart';
import 'package:$appName/router/app_router.dart';

/// Initializes non-critical components after the first frame is rendered.
///
/// Post-launch initializers handle setup that can happen in the background:
/// - Analytics initialization
/// - Feature flag fetching
/// - Remote config syncing
class PostLaunchInitializer extends Initializer {
  PostLaunchInitializer._({
    required this.context,
    required this.router,
  });

  factory PostLaunchInitializer.create({
    required BuildContext context,
    required AppRouter router,
  }) => PostLaunchInitializer._(context: context, router: router);

  final BuildContext context;
  final AppRouter router;

  @override
  Future<InitializerResult> initialize() async {
    // Add post-launch initialization here (analytics, feature flags, etc.)
    return const InitializerResult.success();
  }

  @override
  Future<bool> dispose() async => true;
}
''';
