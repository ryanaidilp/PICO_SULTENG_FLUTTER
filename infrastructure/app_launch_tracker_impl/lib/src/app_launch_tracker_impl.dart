import 'dart:async';

import 'package:app_launch_tracker_impl/src/app_launch_metrics.dart';
import 'package:app_launch_tracker_impl/src/launch_time_tracker_channel.dart';
import 'package:app_launch_tracker_impl/src/launch_trace.dart';
import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// Zone key holding the `(tracker, span)` a block runs inside, so a nested
/// [AppLaunchTracker.traceSpan] or [traceLaunchStep] finds its parent.
final Object _spanZoneKey = Object();

/// Records [block] as a child span of the launch span it runs inside (an
/// initializer run by the host's initializer runner, or another step).
///
/// Outside a launch span, or after the launch trace is final, it only runs
/// [block]. No DI lookup needed:
///
/// ```dart
/// await traceLaunchStep('openDatabase', () => database.open());
/// ```
Future<T> traceLaunchStep<T>(String name, FutureOr<T> Function() block) async {
  final scope = Zone.current[_spanZoneKey] as (AppLaunchTracker, _Span)?;
  if (scope == null) return await block();
  return await scope.$1.traceSpan(name, block);
}

/// Dart-side launch clock. A top-level final starts on first read: at
/// [markDartMain] when the app calls it, otherwise at the tracker's start.
final Stopwatch _dartClock = Stopwatch()..start();

/// Dart-side markers recorded before or outside a tracker, by wire key, in
/// [_dartClock] µs.
final Map<String, int> _dartMarkersUs = {};

/// Records the `dart_main` marker. Call it first in `main()` (the host's
/// `bootstrap()` does). Later calls are ignored.
void markDartMain() => _dartMarkersUs.putIfAbsent(
  'dart_main',
  () => _dartClock.elapsedMicroseconds,
);

/// Removes a splash kept with `FlutterNativeSplash.preserve(...)` and records
/// when the app released it (`native_splash_remove`):
///
/// ```dart
/// removeNativeSplash(FlutterNativeSplash.remove);
/// ```
///
/// `preserve` holds Flutter's first frame, so the native splash exit markers
/// follow on the next frame the platform draws.
void removeNativeSplash(void Function() remove) {
  _dartMarkersUs.putIfAbsent(
    'native_splash_remove',
    () => _dartClock.elapsedMicroseconds,
  );
  remove();
}

/// App launch tracker that records milestone timestamps, step/duration
/// traces and a structured [LaunchTrace] (spans per phase and initializer),
/// then prints a summary and pushes OTLP spans when monitoring is available.
///
/// Ships in every flavor (ADR-030 amendment): no noop twin. The spans leave
/// the device only through [AppMonitoring], which is consent-gated.
@lazySingleton
class AppLaunchTracker({
  // `@ignoreParam` (Archipelago-i9rh): neither param is registered anywhere
  // in GetIt by design — `channel` self-defaults below, and `monitoring` is
  // resolved lazily and defensively via the `_monitoring` getter's own
  // `GetIt.instance.isRegistered<AppMonitoring>()` check, precisely so this
  // class degrades gracefully when monitoring isn't wired. Without
  // `@ignoreParam`, injectable_generator still emits
  // `gh<LaunchTimeTrackerChannel>()`/`gh<AppMonitoring>()` for these
  // optional/nullable params (it does not infer "skip DI, use the
  // constructor's own fallback" from nullability or the `??` default alone),
  // and `LaunchTimeTrackerChannel` has no `@injectable`/`@singleton` of its
  // own anywhere — so every real GetIt resolution of `AppLaunchTracker`
  // threw `GetIt: Object/factory with type LaunchTimeTrackerChannel is not
  // registered`, unconditionally, on first launch of every generated app.
  // Both params exist only so tests can construct this class directly with
  // overrides, bypassing GetIt entirely.
  @ignoreParam LaunchTimeTrackerChannel? channel,
  @ignoreParam AppMonitoring? monitoring,
}) {
  final LaunchTimeTrackerChannel _channel =
      channel ?? const LaunchTimeTrackerChannel();
  final AppMonitoring? _monitoringOverride = monitoring;

  /// Caps a runaway caller; a real launch records a few dozen spans.
  static const int maxSpans = 512;

  /// Monotonic clock for every interval. Zero is [start].
  final Stopwatch _stopwatch = Stopwatch();

  /// Wall clock at [start], read once to line the Dart clock up with the
  /// native epoch timestamps.
  int? _anchorEpochUs;

  /// [_dartClock] at [start], to place the Dart-side markers.
  int _dartClockAtStartUs = 0;

  int? _preLaunchUs;
  int? _firstFrameUs;
  int? _postLaunchStartUs;
  int? _postLaunchEndUs;

  final List<_Span> _spans = [];
  LaunchTrace? _launchTrace;
  final StreamController<LaunchTrace> _launchTraceController =
      StreamController<LaunchTrace>.broadcast();

  /// Native markers by wire key, in wall-clock µs since the Unix epoch.
  final Map<String, int> _nativeEpochUs = {};
  LaunchType? _launchType;

  final List<MetricTrace> _steps = [];
  final List<MetricTrace> _traces = [];

  AppMonitoring? get _monitoring {
    if (_monitoringOverride != null) return _monitoringOverride;
    final gi = GetIt.instance;
    if (!gi.isRegistered<AppMonitoring>()) return null;
    return gi.get<AppMonitoring>();
  }

  /// Seeds process start and engine attach, in ms since the Unix epoch.
  void seedNativeTimestamps({
    required int nativeStartMs,
    required int hostStartMs,
  }) {
    _nativeEpochUs
      ..['process_start'] = nativeStartMs * 1000
      ..['engine_attach'] = hostStartMs * 1000;
  }

  /// Merges the native milestones the platform reported.
  void seedNative(LaunchTimestamps timestamps) {
    _nativeEpochUs.addAll(timestamps.epochUs);
    _launchType = timestamps.launchType ?? _launchType;
  }

  /// The finished trace of this launch, or `null` until post-launch
  /// completes.
  LaunchTrace? get lastLaunchTrace => _launchTrace;

  /// Emits once, when post-launch completes. Late listeners read
  /// [lastLaunchTrace] instead.
  Stream<LaunchTrace> get launchTraces => _launchTraceController.stream;

  /// The trace so far, for a launch that never finished (for example a
  /// pre-launch failure). Unfinished spans are left out.
  LaunchTrace launchTraceSnapshot() => _launchTrace ?? _buildLaunchTrace();

  void start() {
    if (!_stopwatch.isRunning) {
      _dartClockAtStartUs = _dartClock.elapsedMicroseconds;
      _stopwatch.start();
      _anchorEpochUs = DateTime.now().microsecondsSinceEpoch;
    }
    recordStep('AppStart');

    // Fire-and-forget: process start and engine attach for the summary.
    // Later milestones arrive with reportInteractive.
    unawaited(
      _channel.fetchTimestamps().then((timestamps) {
        if (timestamps != null) seedNative(timestamps);
      }),
    );
  }

  void markPreLaunchCompleted() {
    _preLaunchUs = _stopwatch.elapsedMicroseconds;
    recordStep('PreLaunchCompleted');
  }

  void markFirstFrameRendered() {
    _firstFrameUs = _stopwatch.elapsedMicroseconds;
    recordStep('FirstFrameRendered');
  }

  void startPostLaunch() {
    _postLaunchStartUs ??= _stopwatch.elapsedMicroseconds;
    recordStep('PostLaunchStarted');
  }

  /// Marks the app interactive. Recording stops here; the trace is final
  /// once the platform has reported its late milestones (native first
  /// frame, splash exit), then [launchTraces] emits it. Later calls are
  /// ignored.
  void markPostLaunchCompleted() {
    if (_postLaunchEndUs != null) return;
    _postLaunchEndUs = _stopwatch.elapsedMicroseconds;
    recordStep('PostLaunchCompleted');
    printSummary();
    _pushOtlpSpans();
    unawaited(_publishLaunchTrace());
  }

  Future<void> _publishLaunchTrace() async {
    final timestamps = await _channel.reportInteractive().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    if (timestamps != null) seedNative(timestamps);
    final trace = _launchTrace = _buildLaunchTrace();
    _launchTraceController.add(trace);
  }

  /// Records [block] as a span of the launch trace and returns its result.
  ///
  /// Inside another span (see [traceLaunchStep]) it becomes that span's
  /// child and inherits its [phase]. Otherwise [phase] defaults to the
  /// phase the launch is in now. A throw marks the span
  /// [LaunchSpanStatus.failed] (a [TimeoutException] marks it
  /// [LaunchSpanStatus.timeout]) and is rethrown; [statusOf] classifies a
  /// returned result. After the trace is final, or before [start], it only
  /// runs [block].
  Future<T> traceSpan<T>(
    String name,
    FutureOr<T> Function() block, {
    LaunchPhase? phase,
    LaunchSpanMode mode = LaunchSpanMode.sequential,
    String? group,
    LaunchSpanStatus Function(T result)? statusOf,
  }) async {
    if (_postLaunchEndUs != null ||
        !_stopwatch.isRunning ||
        _spans.length >= maxSpans) {
      return await block();
    }
    final scope = Zone.current[_spanZoneKey] as (AppLaunchTracker, _Span)?;
    final parent = identical(scope?.$1, this) ? scope!.$2 : null;
    final span = _Span(
      id: _spans.length + 1,
      parent: parent,
      name: name,
      phase: phase ?? parent?.phase ?? _currentPhase,
      mode: mode,
      group: group,
      startUs: _stopwatch.elapsedMicroseconds,
    );
    _spans.add(span);
    try {
      final result = await runZoned(
        () async => await block(),
        zoneValues: {_spanZoneKey: (this, span)},
      );
      span.status = statusOf?.call(result) ?? LaunchSpanStatus.ok;
      return result;
    } on TimeoutException {
      span.status = LaunchSpanStatus.timeout;
      rethrow;
    } catch (_) {
      span.status = LaunchSpanStatus.failed;
      rethrow;
    } finally {
      span.endUs = _stopwatch.elapsedMicroseconds;
    }
  }

  LaunchPhase get _currentPhase => _preLaunchUs == null
      ? LaunchPhase.preLaunch
      : _firstFrameUs == null
      ? LaunchPhase.firstFrame
      : LaunchPhase.postLaunch;

  void recordStep(String step) {
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint('Trace::Timing::$step::$now');
    _steps.add(MetricTrace(name: step, timestampMillis: now));
  }

  void recordDuration(String name, int durationMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint('Trace::Duration::$name::$durationMs::ms');
    _traces.add(
      MetricTrace(
        name: name,
        timestampMillis: now,
        durationMilliseconds: durationMs,
      ),
    );
  }

  void printSummary() {
    debugPrint('===== App Launch Summary =====');
    final metrics = _buildMetrics();
    if (metrics.nativeStartMs != null && metrics.hostStartMs != null) {
      final nativeToHost = metrics.hostStartMs! - metrics.nativeStartMs!;
      debugPrint('  NativeToHost: $nativeToHost ms');
    }
    debugPrint('  PreLaunch:    ${metrics.preLaunchMs ?? '-'} ms');
    debugPrint('  FirstFrame:   ${metrics.firstFrameMs ?? '-'} ms');
    debugPrint('  PostLaunch:   ${metrics.postLaunchMs ?? '-'} ms');
    final total = (metrics.firstFrameMs ?? 0) + (metrics.postLaunchMs ?? 0);
    debugPrint('  TotalStartup: $total ms');
    if (_steps.isNotEmpty) {
      debugPrint('  Steps: ${_steps.map((s) => s.name).join(' -> ')}');
    }
    debugPrint('==============================');
  }

  /// Returns a snapshot of captured metrics for internal use.
  ///
  /// Not part of the public surface — use [printSummary] or rely on Grafana
  /// push for reporting.
  AppLaunchMetrics getMetricsSnapshot() => _buildMetrics();

  AppLaunchMetrics _buildMetrics() {
    final firstFrameMs = _ms(_firstFrameUs);
    final postEnd = _postLaunchEndUs;
    final postLaunchMs = postEnd == null
        ? null
        : (postEnd - (_postLaunchStartUs ?? postEnd)) ~/ 1000;
    final total = (firstFrameMs ?? 0) + (postLaunchMs ?? 0);
    return AppLaunchMetrics(
      preLaunchMs: _ms(_preLaunchUs),
      firstFrameMs: firstFrameMs,
      postLaunchMs: postLaunchMs,
      totalStartupMs: total > 0 ? total : null,
      nativeStartMs: _epochMs('process_start'),
      hostStartMs: _epochMs('engine_attach'),
      steps: List.unmodifiable(_steps),
      traces: List.unmodifiable(_traces),
    );
  }

  static int? _ms(int? us) => us == null ? null : us ~/ 1000;

  int? _epochMs(String key) => _ms(_nativeEpochUs[key]);

  LaunchTrace _buildLaunchTrace() {
    final anchorUs = _anchorEpochUs ?? DateTime.now().microsecondsSinceEpoch;

    // The earliest native time is the origin. One after the Dart anchor
    // means the wall clock jumped; skip it rather than emit negative
    // offsets.
    var origin = LaunchTraceOrigin.dartStart;
    var originUs = anchorUs;
    for (final candidate in const [
      LaunchTraceOrigin.launchRequested,
      LaunchTraceOrigin.processStart,
      LaunchTraceOrigin.engineAttach,
    ]) {
      final us = _nativeEpochUs[candidate.wireName];
      if (us != null && us <= anchorUs) {
        origin = candidate;
        originUs = us;
        break;
      }
    }
    final shiftUs = anchorUs - originUs;
    double at(int dartUs) => (dartUs + shiftUs) / 1000;

    // Markers before the origin (a stale native time) are dropped.
    final markers = <String, double>{
      for (final MapEntry(:key, value: us) in _nativeEpochUs.entries)
        if (us >= originUs) key: (us - originUs) / 1000,
      for (final MapEntry(:key, value: us) in _dartMarkersUs.entries)
        if (at(us - _dartClockAtStartUs) >= 0)
          key: at(us - _dartClockAtStartUs),
    };
    final processStartMs = markers.remove('process_start');
    final engineAttachMs = markers.remove('engine_attach');

    final spans = <LaunchSpan>[];
    void addSpan(
      String id,
      LaunchPhase phase,
      double? startMs,
      double? endMs, {
      String? parentId,
    }) {
      if (startMs == null || endMs == null || endMs < startMs) return;
      spans.add(
        LaunchSpan(
          id: id,
          parentId: parentId,
          name: id,
          phase: phase,
          startOffsetMs: startMs,
          durationMs: endMs - startMs,
          blocksFirstFrame: phase.blocksFirstFrame,
        ),
      );
    }

    void phaseSpan(LaunchPhase phase, double? startMs, double? endMs) =>
        addSpan(phase.wireName, phase, startMs, endMs);

    final dartStartMs = at(0);
    final preUs = _preLaunchUs;
    final firstFrameUs = _firstFrameUs;
    final postStartUs = _postLaunchStartUs;
    final postEndUs = _postLaunchEndUs;
    phaseSpan(LaunchPhase.native, processStartMs, engineAttachMs);
    phaseSpan(LaunchPhase.engine, engineAttachMs, dartStartMs);
    phaseSpan(
      LaunchPhase.preLaunch,
      dartStartMs,
      preUs == null ? null : at(preUs),
    );
    phaseSpan(
      LaunchPhase.firstFrame,
      preUs == null ? null : at(preUs),
      firstFrameUs == null ? null : at(firstFrameUs),
    );
    phaseSpan(
      LaunchPhase.postLaunch,
      postStartUs == null ? null : at(postStartUs),
      postEndUs == null ? null : at(postEndUs),
    );

    // Native steps nest under the native phase, so phase totals do not
    // count them twice. Without that phase they are roots.
    final nativeParent = spans.any((s) => s.id == LaunchPhase.native.wireName)
        ? LaunchPhase.native.wireName
        : null;
    addSpan(
      'native_app_init',
      LaunchPhase.native,
      markers['native_app_init_start'],
      markers['native_app_init_end'],
      parentId: nativeParent,
    );
    final splashExitStart = markers['native_splash_exit_start'];
    final splashExitEnd = markers['native_splash_exit_end'];
    addSpan(
      'native_splash',
      LaunchPhase.native,
      markers['native_splash_shown'],
      splashExitEnd ?? splashExitStart,
      parentId: nativeParent,
    );
    if (splashExitStart != null &&
        splashExitEnd != null &&
        splashExitEnd > splashExitStart) {
      addSpan(
        'native_splash_exit',
        LaunchPhase.native,
        splashExitStart,
        splashExitEnd,
        parentId: spans.any((s) => s.id == 'native_splash')
            ? 'native_splash'
            : nativeParent,
      );
    }

    // A span still running (e.g. abandoned by a timeout) is left out, and a
    // child whose parent is left out becomes a root.
    final ids = {
      for (final span in spans) span.id,
      for (final span in _spans)
        if (span.endUs != null) '${span.id}',
    };
    for (final span in _spans) {
      final endUs = span.endUs;
      if (endUs == null) continue;
      final parentId = span.parent == null
          ? span.phase.wireName
          : '${span.parent!.id}';
      spans.add(
        LaunchSpan(
          id: '${span.id}',
          parentId: ids.contains(parentId) ? parentId : null,
          name: span.name,
          phase: span.phase,
          startOffsetMs: at(span.startUs),
          durationMs: (endUs - span.startUs) / 1000,
          mode: span.mode,
          group: span.group,
          blocksFirstFrame: span.phase.blocksFirstFrame,
          status: span.status,
        ),
      );
    }
    spans.sort((a, b) => a.startOffsetMs.compareTo(b.startOffsetMs));

    return LaunchTrace(
      origin: origin,
      originEpochMs: originUs ~/ 1000,
      launchType: _launchType,
      processStartMs: processStartMs,
      engineAttachMs: engineAttachMs,
      firstFrameMs: firstFrameUs == null ? null : at(firstFrameUs),
      interactiveMs: postEndUs == null ? null : at(postEndUs),
      otherMarkers: markers,
      spans: spans,
    );
  }

  /// Pushes OTLP spans per phase to Grafana Tempo via [AppMonitoring].
  ///
  /// Soft no-op when monitoring is unavailable or not yet initialised.
  /// Uses [AppMonitoring.recordTransaction] as the span primitive — no
  /// dependency on any concrete Grafana impl.
  void _pushOtlpSpans() {
    final monitoring = _monitoring;
    if (monitoring == null || !monitoring.isEnabled) return;

    final metrics = _buildMetrics();
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final platform = defaultTargetPlatform.name;

    // Parent span covering the entire launch — fire-and-forget.
    unawaited(
      monitoring.recordTransaction(
        'app_launch',
        () async {
          // Child span: native-to-host phase (process start → engine attach).
          if (metrics.nativeStartMs != null && metrics.hostStartMs != null) {
            await monitoring.recordTransaction(
              'app_launch:native_to_host',
              () async {},
              data: {
                'phase': 'native_to_host',
                'flavor': flavor,
                'platform': platform,
                'duration_ms': metrics.hostStartMs! - metrics.nativeStartMs!,
              },
            );
          }

          // Child span: pre-launch phase (DI, critical SDKs).
          if (metrics.preLaunchMs != null) {
            await monitoring.recordTransaction(
              'app_launch:pre_launch',
              () async {},
              data: {
                'phase': 'pre_launch',
                'flavor': flavor,
                'platform': platform,
                'duration_ms': metrics.preLaunchMs,
              },
            );
          }

          // Child span: first frame phase.
          if (metrics.firstFrameMs != null) {
            await monitoring.recordTransaction(
              'app_launch:first_frame',
              () async {},
              data: {
                'phase': 'first_frame',
                'flavor': flavor,
                'platform': platform,
                'duration_ms': metrics.firstFrameMs,
              },
            );
          }

          // Child span: post-launch phase (analytics, flags).
          if (metrics.postLaunchMs != null) {
            await monitoring.recordTransaction(
              'app_launch:post_launch',
              () async {},
              data: {
                'phase': 'post_launch',
                'flavor': flavor,
                'platform': platform,
                'duration_ms': metrics.postLaunchMs,
              },
            );
          }
        },
        data: {
          'total_startup_ms': metrics.totalStartupMs,
          'flavor': flavor,
          'platform': platform,
          'native_start_ms': metrics.nativeStartMs,
          'host_start_ms': metrics.hostStartMs,
        },
      ),
    );

    debugPrint(
      '[AppLaunchTracker] OTLP spans pushed: '
      'total=${metrics.totalStartupMs}ms flavor=$flavor platform=$platform',
    );
  }
}

/// Mutable record of one in-flight or finished span. Kept small: recording
/// allocates this, a zone and a closure per span, nothing else.
class _Span({
  required final int id,
  required final _Span? parent,
  required final String name,
  required final LaunchPhase phase,
  required final LaunchSpanMode mode,
  required final String? group,
  required final int startUs,
}) {
  int? endUs;
  LaunchSpanStatus status = LaunchSpanStatus.ok;
}
