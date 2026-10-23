import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';

/// Registers a feature's types into its own [child] container.
///
/// [root] is the app-wide `GetIt.instance`. Read from it only to import the
/// globals the feature declares (see [FeatureContainer]).
typedef FeatureContainerBuild = FutureOr<void> Function(
  GetIt child,
  GetIt root,
);

/// A feature's own DI container: a child `GetIt.asNewInstance()` with a
/// ref-counted, awaited lifecycle.
///
/// The child never falls back to the root. It resolves only what `build`
/// registered into it, so one feature cannot resolve another feature's
/// types, and a port lives in exactly one place. A global the feature needs
/// is imported explicitly in `build`, as a factory that delegates to the
/// root, so the root keeps ownership and the child's teardown never
/// disposes it:
///
/// ```dart
/// final authContainer = FeatureContainer(
///   'auth',
///   root: GetIt.instance,
///   build: (child, root) {
///     child.registerFactory<HttpClient>(() => root<HttpClient>());
///     initAuthLocalDI(child);
///   },
/// );
/// ```
///
/// The first [acquire] builds the child; when the last [FeatureLease] is
/// released, the child is torn down with `reset(dispose: true)`. An
/// [acquire] made while that teardown runs waits for it, then builds a fresh
/// child. A failed `build` is torn down at once, so a later [acquire]
/// retries from scratch.
///
/// This replaces ADR-002's named scope on the shared `GetIt.instance`,
/// whose implicit fallback made every pushed feature visible to all code.
///
/// `name` is the feature name, used in error messages and [debugSnapshot].
final class FeatureContainer(
  final String name, {
  required final GetIt _root,
  required final FeatureContainerBuild _build,
}) {
  var _leases = 0;
  Future<GetIt>? _child;
  Future<void>? _teardown;

  /// Takes a lease on the child container, building it on first use.
  ///
  /// Await [FeatureLease.ready] before resolving. Release every lease, even
  /// one whose `ready` failed or is still pending.
  FeatureLease acquire() {
    _leases++;
    return FeatureLease._(this);
  }

  Future<GetIt?> _ready(FeatureLease lease) async {
    // A while-case pattern trips a dart_style 3.13 bug; keep the null check.
    for (var t = _teardown; t != null; t = _teardown) {
      // A teardown failure belongs to the releaser that started it.
      try {
        await t;
      } on Object catch (_) {}
    }
    // Released while waiting: building now would leak a child nobody holds.
    if (lease._released) return null;
    return await (_child ??= _startBuild());
  }

  Future<GetIt> _startBuild() async {
    final child = GetIt.asNewInstance();
    // Future.sync so a synchronous throw from build still reaches catch
    // after the caller has stored this future in _child.
    try {
      await Future.sync(() => _build(child, _root));
      return child;
    } on Object {
      // _child is either this build or already cleared by a release: no new
      // build starts until this one settles, because the release's teardown
      // awaits it. Clearing lets the next acquire retry.
      _child = null;
      try {
        await child.reset();
      } on Object catch (error, stack) {
        // The build error is the one rethrown; report this one so it is
        // not lost.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'feature_sdk',
            context: ErrorDescription('tearing down failed $name container'),
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _release() {
    if (--_leases > 0) return Future.value();
    final child = _child;
    if (child == null) return Future.value();
    _child = null;
    final teardown = _teardown = _tearDown(child);
    return teardown.whenComplete(() {
      if (identical(_teardown, teardown)) _teardown = null;
    });
  }

  Future<void> _tearDown(Future<GetIt> build) async {
    final GetIt child;
    try {
      child = await build;
    } on Object catch (_) {
      // The failed build tore itself down and threw to every ready.
      return;
    }
    await child.reset();
  }

  /// Lease count and lifecycle state, for tests and the debugger.
  ({String name, int leases, bool built, bool tearingDown}) debugSnapshot() => (
    name: name,
    leases: _leases,
    built: _child != null,
    tearingDown: _teardown != null,
  );
}

/// One holder's claim on a [FeatureContainer]'s child.
///
/// Take it in `initState`, build content after [ready], and release it in
/// `dispose`:
///
/// ```dart
/// late final _lease = authContainer.acquire();
///
/// @override
/// void dispose() {
///   unawaited(_lease.release().catchError(_report));
///   super.dispose();
/// }
/// ```
final class FeatureLease._(final FeatureContainer _container) {
  this {
    ready = _container._ready(this).then((child) => _child = child);
  }
  GetIt? _child;
  var _released = false;
  Future<void>? _release;

  /// Completes once the child is built; throws what the build threw.
  late final Future<void> ready;

  /// Resolves [T] from the child only. Throws if [T] was not registered or
  /// imported, before [ready], and after [release].
  T get<T extends Object>({String? instanceName}) {
    final child = _child;
    if (child == null || _released) {
      throw StateError(
        '${_container.name} lease is ${_released ? 'released' : 'not ready'}',
      );
    }
    return child.get<T>(instanceName: instanceName);
  }

  /// Gives the lease back. The last release tears the child down and
  /// completes once that is done; teardown errors are thrown here.
  /// Safe to call more than once, and before [ready] completes.
  Future<void> release() {
    _released = true;
    return _release ??= _container._release();
  }
}
