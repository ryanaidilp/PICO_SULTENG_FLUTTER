import 'dart:async';

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_utilities/app_utilities.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/material.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/host/initializers/initializer.dart';
import 'package:pico/host/initializers/post_launch_initializer.dart';
import 'package:pico/host/initializers/pre_launch_initializer.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Builder function for [HostAppWidget].
///
/// Called after initialization completes with the [result].
typedef HostAppWidgetBuilder = Widget Function(
  BuildContext context,
  InitializerResult result,
);

/// Builder function for error widget in [HostAppWidget].
///
/// Called when initialization fails with the [error] and [stackTrace].
/// [onRetry] re-runs pre-launch initialization from scratch — call it from
/// the widget's retry affordance (e.g. a button's `onPressed`).
typedef HostAppErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
  VoidCallback onRetry,
);

/// The root widget that manages app initialization lifecycle.
///
/// This widget orchestrates the two-phase initialization process:
///
/// 1. **Pre-launch**: Runs immediately in `initState`, blocks UI rendering
/// 2. **Post-launch**: Runs after pre-launch completes successfully
///
/// Launch timing is captured via [AppLaunchTracker] when one is registered
/// (every flavor, ADR-030); without one, tracking is skipped.
///
/// Content transitions are smoothly animated using [AnimatedSwitcher].
///
/// A pre-launch failure — whether `initializerController.initialize()`
/// throws, or resolves with an [InitializerResult] whose
/// `isInitializationSuccessful` is `false` — is surfaced identically through
/// [errorBuilder] (or the default fallback). Retrying re-invokes
/// `initializerController.initialize()` from scratch; see the private state
/// class's `_runInitialization` method.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   runApp(
///     HostAppWidget(
///       initializerController: PreLaunchInitializerController.create(),
///       builder: (context, result) => MyApp(router: result.requireRouter),
///     ),
///   );
/// }
/// ```
class const HostAppWidget({
  /// Builds the app UI after initialization completes.
  required final HostAppWidgetBuilder builder,

  /// The controller managing pre-launch initialization lifecycle.
  required final PreLaunchInitializerController initializerController,

  /// Called after post-launch initialization completes successfully.
  final VoidCallback? postInitializeCallback,

  /// Widget to display during initialization.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loadingWidget,

  /// Builds the error widget when initialization fails.
  ///
  /// Defaults to a simple error text display with a retry button.
  final HostAppErrorBuilder? errorBuilder,

  /// Duration of the transition animation between states.
  ///
  /// Defaults to 300 milliseconds.
  final Duration transitionDuration = const Duration(milliseconds: 300),

  /// Custom transition builder for the animated switcher.
  ///
  /// Defaults to a [FadeTransition].
  final AnimatedSwitcherTransitionBuilder? transitionBuilder,
  super.key,
}) extends StatefulWidget {
  @override
  State<HostAppWidget> createState() => _HostAppWidgetState();
}

class _HostAppWidgetState() extends State<HostAppWidget> {
  /// The in-flight (or most recently completed) pre-launch attempt.
  ///
  /// Reassigned by [_retry] to re-run initialization — [FutureBuilder]
  /// picks up the new future on the next build because `future` is compared
  /// by identity, not by contents.
  late Future<InitializerResult> _initializationFuture;

  PostLaunchInitializer? _postLaunchInitializer;

  /// Null when no tracker is registered (e.g. widget tests). Started in
  /// [initState], before pre-launch runs, so pre-launch is timed.
  AppLaunchTracker? _launchTracker;

  /// Listens for app shutdown so registered feature manifests can be disposed.
  ///
  /// Created eagerly in [initState] (not as a `late final` field, which
  /// would only construct — and start observing — on first read, too late
  /// if that read happened in [dispose]) so it observes for the widget's
  /// full lifetime and disposed in [dispose], the symmetric counterpart to
  /// [FeatureManifest.initialize] being called from [PreLaunchInitializer].
  ///
  /// `onDetach` fires on all platforms when the last view is detached from
  /// the engine, which is as close to a general "app shutdown" hook as
  /// Flutter provides; there is no guarantee of this on OS-killed mobile
  /// processes, but it covers graceful shutdown paths (desktop/web window
  /// close, and detach during navigation-away on mobile).
  AppLifecycleListener? _lifecycleListener;

  @override
  Widget build(BuildContext context) => FutureBuilder<InitializerResult>(
    future: _initializationFuture,
    builder: (_, snapshot) {
      final Widget child;

      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          child = KeyedSubtree(
            key: const ValueKey('error'),
            child: _BootstrapThemeShell(
              child: _buildErrorWidget(
                context,
                snapshot.error!,
                snapshot.stackTrace,
                _retry,
              ),
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
          child: _BootstrapThemeShell(child: _buildLoadingWidget()),
        );
      }

      // Themed colour behind the cross-fade (OS brightness is all that is
      // known this early) so no light frame shows between boot and app.
      final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      return ColoredBox(
        color: dark ? PicoBrandPalette.paperDark : PicoBrandPalette.paperLight,
        child: AnimatedSwitcher(
          duration: widget.transitionDuration,
          transitionBuilder: widget.transitionBuilder ?? _defaultTransition,
          child: child,
        ),
      );
    },
  );

  Widget _buildLoadingWidget() =>
      widget.loadingWidget ?? const Center(child: CircularProgressIndicator());

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    VoidCallback onRetry,
  ) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace, onRetry);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'There is something wrong: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _defaultTransition(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);

  @override
  void initState() {
    super.initState();

    _launchTracker = getIt.isRegistered<AppLaunchTracker>()
        ? (getIt<AppLaunchTracker>()..start())
        : null;
    _lifecycleListener = AppLifecycleListener(onDetach: _disposeFeatures);
    _initializationFuture = _runInitialization();
  }

  /// Runs pre-launch initialization once, and — on success — schedules
  /// post-launch to start after the first post-pre-launch frame renders.
  ///
  /// A returned failure (`isInitializationSuccessful == false`) is
  /// re-thrown so it reaches [FutureBuilder]'s `snapshot.hasError` branch
  /// the same way a thrown error would — the two used to be handled
  /// differently (a returned failure silently fell through to
  /// `widget.builder` with a null router), which is exactly the kind of
  /// gap [InitializerCriticality]/timeout classification in
  /// `initializer_runner.dart` now surfaces as ordinary returned failures
  /// instead of uncaught exceptions.
  ///
  /// Called again by [_retry] to re-attempt initialization; the same
  /// [PreLaunchInitializerController]/`PreLaunchInitializer` instance (and
  /// its individual [Initializer]s) is reused, so retried steps must be
  /// safe to invoke more than once — see the cancellation caveat on
  /// [Initializer.timeout].
  Future<InitializerResult> _runInitialization() async {
    final result = await widget.initializerController.initialize();

    if (!mounted) return result;

    if (!result.isInitializationSuccessful) {
      // InitializerResult.error is a bare Object? (an Initializer may pass
      // anything to InitializerResult.failure), so normalize to a real
      // Error/Exception before throwing — only_throw_errors requires it,
      // and it keeps FutureBuilder's snapshot.error consistently
      // throwable-typed.
      final error = result.error;
      if (error is Error) throw error;
      if (error is Exception) throw error;
      throw Exception(error?.toString() ?? 'Pre-launch initialization failed');
    }

    _launchTracker?.markPreLaunchCompleted();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _launchTracker?.markFirstFrameRendered();

      final postLaunchInitializer = PostLaunchInitializer.create(
        context: context,
        router: result.requireRouter,
      );
      _postLaunchInitializer = postLaunchInitializer;
      _launchTracker?.startPostLaunch();

      await postLaunchInitializer.initialize();

      _launchTracker?.markPostLaunchCompleted();

      if (mounted) {
        widget.postInitializeCallback?.call();
      }
    });

    return result;
  }

  /// Re-runs pre-launch initialization from scratch.
  ///
  /// Reassigns [_initializationFuture] inside [setState] so [FutureBuilder]
  /// observes a new future (identity-compared) and resets to the loading
  /// state while it resolves.
  void _retry() {
    setState(() {
      _initializationFuture = _runInitialization();
    });
  }

  @override
  void dispose() {
    widget.initializerController.dispose();
    _postLaunchInitializer?.dispose();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  /// Fire-and-forget disposal of every registered feature manifest.
  ///
  /// Each manifest is disposed independently (see [_safeDispose]) so one
  /// `dispose()` failure never blocks the others from shutting down
  /// cleanly — mirrors the per-initializer isolation `runInitializer`
  /// (`initializer_runner.dart`) applies during initialization.
  void _disposeFeatures() {
    for (final manifest in FeatureSDKRegistry.instance.manifests) {
      unawaited(_safeDispose(manifest));
    }
  }

  Future<void> _safeDispose(FeatureManifest manifest) async {
    try {
      await manifest.dispose();
    } catch (error, stackTrace) {
      getIt<Log>().e(
        '[HostAppWidget] ${manifest.runtimeType}.dispose() threw',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Minimal Material/theme ancestor for the loading and error states.
///
/// [HostAppWidget] is mounted directly by `runApp` — the app's own
/// `MaterialApp.router` (with `PicoTheme.light()`/`PicoTheme.dark()`) only
/// exists once [HostAppWidget.builder] runs after a *successful*
/// initialization. Without this shell, the loading/error content has no
/// `Directionality`/`Theme` ancestor: the default loading indicator happens
/// to not need one, but the error branch's `Text` (and any UI-kit
/// `context.colors`/`context.typography` usage in a custom `errorBuilder`,
/// per this project's UI-kit conventions) does.
///
/// Deliberately not wrapping the successful "app" branch — that branch
/// already brings its own full `MaterialApp.router`, and nesting a second
/// one around it would be wasteful and could conflict with its `Navigator`.
class const _BootstrapThemeShell({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PicoTheme.light(),
    darkTheme: PicoTheme.dark(),
    home: child,
  );
}
