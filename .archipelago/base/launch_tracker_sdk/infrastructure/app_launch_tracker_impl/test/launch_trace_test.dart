import 'dart:async';
import 'dart:convert';

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_launch_tracker_impl/src/launch_time_tracker_channel.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoChannel() extends LaunchTimeTrackerChannel {
  @override
  Future<LaunchTimestamps?> fetchTimestamps() async => null;

  @override
  Future<LaunchTimestamps?> reportInteractive() async => null;
}

/// Reports [late] only with `reportInteractive`, as a platform does for the
/// milestones that happen after the tracker starts.
class _LateChannel(final LaunchTimestamps late)
    extends LaunchTimeTrackerChannel {
  @override
  Future<LaunchTimestamps?> fetchTimestamps() async => null;

  @override
  Future<LaunchTimestamps?> reportInteractive() async => late;
}

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

LaunchSpan _span(LaunchTrace trace, String name) =>
    trace.spans.singleWhere((s) => s.name == name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLaunchTracker tracker;

  setUp(() {
    tracker = AppLaunchTracker(channel: _NoChannel())..start();
  });

  Future<LaunchTrace> finish() {
    final published = tracker.launchTraces.first;
    tracker
      ..markPreLaunchCompleted()
      ..markFirstFrameRendered()
      ..startPostLaunch()
      ..markPostLaunchCompleted();
    return published;
  }

  test('a parallel batch shares a group and overlaps in time', () async {
    Future<void> batchMember(String name) => tracker.traceSpan(
      name,
      () => _wait(20),
      phase: LaunchPhase.preLaunch,
      mode: LaunchSpanMode.parallel,
      group: 'pre_launch.parallel',
    );
    await Future.wait([batchMember('a'), batchMember('b')]);
    final trace = await finish();

    final a = _span(trace, 'a');
    final b = _span(trace, 'b');
    expect(a.group, 'pre_launch.parallel');
    expect(b.group, a.group);
    expect(a.mode, LaunchSpanMode.parallel);
    expect(a.startOffsetMs < b.endOffsetMs, isTrue);
    expect(b.startOffsetMs < a.endOffsetMs, isTrue);
  });

  test('sequential spans run back to back', () async {
    await tracker.traceSpan('first', () => _wait(10));
    await tracker.traceSpan('second', () => _wait(10));
    final trace = await finish();

    final first = _span(trace, 'first');
    final second = _span(trace, 'second');
    expect(first.mode, LaunchSpanMode.sequential);
    expect(first.group, isNull);
    expect(second.startOffsetMs, greaterThanOrEqualTo(first.endOffsetMs));
    expect(first.durationMs, greaterThanOrEqualTo(10));
  });

  test('records failed and timed-out spans, then rethrows', () async {
    await expectLater(
      tracker.traceSpan<void>('throws', () => throw StateError('boom')),
      throwsStateError,
    );
    await expectLater(
      tracker.traceSpan(
        'hangs',
        () => _wait(500).timeout(const Duration(milliseconds: 5)),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await tracker.traceSpan(
      'returns failure',
      () => false,
      statusOf: (ok) => ok ? LaunchSpanStatus.ok : LaunchSpanStatus.failed,
    );
    final trace = await finish();

    expect(_span(trace, 'throws').status, LaunchSpanStatus.failed);
    expect(_span(trace, 'hangs').status, LaunchSpanStatus.timeout);
    expect(_span(trace, 'returns failure').status, LaunchSpanStatus.failed);
  });

  test('child spans nest under the span they run in', () async {
    await tracker.traceSpan('initializer', () async {
      await traceLaunchStep('step', () async {
        await traceLaunchStep('sub-step', () => _wait(1));
      });
    }, phase: LaunchPhase.preLaunch);
    final trace = await finish();

    final parent = _span(trace, 'initializer');
    final step = _span(trace, 'step');
    final subStep = _span(trace, 'sub-step');
    expect(parent.parentId, LaunchPhase.preLaunch.wireName);
    expect(step.parentId, parent.id);
    expect(subStep.parentId, step.id);
    expect(subStep.phase, LaunchPhase.preLaunch);
  });

  test('traceLaunchStep outside a launch span only runs the block', () async {
    expect(await traceLaunchStep('orphan', () => 42), 42);
    expect((await finish()).spans.where((s) => s.name == 'orphan'), isEmpty);
  });

  test(
    'pre-launch spans block the first frame, post-launch spans do not',
    () async {
      await tracker.traceSpan('pre', () => _wait(1));
      tracker
        ..markPreLaunchCompleted()
        ..markFirstFrameRendered()
        ..startPostLaunch();
      await tracker.traceSpan('post', () => _wait(1));
      final published = tracker.launchTraces.first;
      tracker.markPostLaunchCompleted();
      final trace = await published;

      expect(_span(trace, 'pre').phase, LaunchPhase.preLaunch);
      expect(_span(trace, 'pre').blocksFirstFrame, isTrue);
      expect(_span(trace, 'post').phase, LaunchPhase.postLaunch);
      expect(_span(trace, 'post').blocksFirstFrame, isFalse);
      expect(_span(trace, 'post').parentId, 'post_launch');
      expect(_span(trace, 'pre_launch').blocksFirstFrame, isTrue);
      expect(trace.firstFrameMs, isNotNull);
      expect(trace.interactiveMs, greaterThanOrEqualTo(trace.firstFrameMs!));
    },
  );

  test('offsets start at process start when native timestamps exist', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    tracker.seedNativeTimestamps(
      nativeStartMs: now - 500,
      hostStartMs: now - 200,
    );
    final trace = await finish();

    expect(trace.origin, LaunchTraceOrigin.processStart);
    expect(trace.processStartMs, 0);
    expect(trace.engineAttachMs, 300);
    expect(_span(trace, 'native').durationMs, 300);
    expect(_span(trace, 'engine').startOffsetMs, 300);
    // The tracker's Dart start is taken in setUp, a few ms before `now` when
    // `melos run test` runs packages in parallel; ~0 would mean Dart start.
    expect(_span(trace, 'pre_launch').startOffsetMs, closeTo(500, 100));
  });

  test('falls back to Dart start without native timestamps', () async {
    final trace = await finish();

    expect(trace.origin, LaunchTraceOrigin.dartStart);
    expect(trace.processStartMs, isNull);
    expect(trace.spans.map((s) => s.id), isNot(contains('native')));
  });

  test('publishes the trace once, then stops recording', () async {
    expect(tracker.lastLaunchTrace, isNull);
    final trace = await finish();

    expect(tracker.lastLaunchTrace, same(trace));
    await tracker.traceSpan('late', () {});
    tracker.markPostLaunchCompleted();
    expect(tracker.lastLaunchTrace, same(trace));
    expect(trace.spans.where((s) => s.name == 'late'), isEmpty);
  });

  test('JSON round-trips and rejects other schema versions', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    tracker.seedNativeTimestamps(
      nativeStartMs: now - 50,
      hostStartMs: now - 20,
    );
    await tracker.traceSpan('init', () async {
      await traceLaunchStep('child', () {});
    });
    final json = (await finish()).toJson();

    final decoded = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
    expect(decoded['schemaVersion'], 1);
    expect(LaunchTrace.fromJson(decoded).toJson(), equals(json));
    expect(
      () => LaunchTrace.fromJson({...decoded, 'schemaVersion': 2}),
      throwsFormatException,
    );
  });

  test('keeps markers it has no field for', () {
    final trace = LaunchTrace.fromJson({
      'schemaVersion': 1,
      'origin': 'process_start',
      'markers': {'first_frame': 700, 'native_first_frame': 412.5},
      'spans': <Object?>[],
    });
    expect(trace.firstFrameMs, 700);
    expect(trace.markers, {'first_frame': 700, 'native_first_frame': 412.5});
    expect(LaunchTrace.fromJson(trace.toJson()).markers, trace.markers);
  });

  test('recording is cheap and capped', () async {
    // ponytail: wall-clock bound, generous for JIT test runs and for
    // `melos run test` running packages in parallel (277us seen under load);
    // tighten if a profile shows recording on the launch path.
    const n = 300;
    final plain = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      await Future<void>.value();
    }
    plain.stop();
    final traced = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      await tracker.traceSpan('s$i', Future<void>.value);
    }
    traced.stop();

    final overheadUs =
        (traced.elapsedMicroseconds - plain.elapsedMicroseconds) / n;
    expect(overheadUs, lessThan(1000));

    for (var i = 0; i < AppLaunchTracker.maxSpans; i++) {
      await tracker.traceSpan('fill$i', () {});
    }
    final recorded = (await finish()).spans.where(
      (s) => s.phase != LaunchPhase.native,
    );
    expect(
      recorded.where((s) => s.id != s.phase.wireName).length,
      AppLaunchTracker.maxSpans,
    );
  });

  group('native milestones', () {
    test('converts monotonic times with the one paired sample', () {
      final timestamps = LaunchTimestamps.fromNative({
        'monoNowMs': 5000.0,
        'epochNowMs': 1700000000000.0,
        'launchType': 'cold',
        'markers': {'process_start': 4000.0, 'engine_attach': 4250.5},
      });

      expect(timestamps.epochUs, {
        'process_start': 1699999999000000,
        'engine_attach': 1699999999250500,
      });
      expect(timestamps.launchType, LaunchType.cold);
      expect(timestamps.nativeStartMs, 1699999999000);
      expect(
        LaunchTimestamps.fromNative({'markers': <String, Object?>{}}).epochUs,
        isEmpty,
      );
    });

    test('merges late native markers and nests the native spans', () async {
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      int ago(int ms) => nowUs - ms * 1000;
      tracker = AppLaunchTracker(
        channel: _LateChannel(
          LaunchTimestamps(
            epochUs: {
              'launch_requested': ago(600),
              'process_start': ago(560),
              'native_splash_shown': ago(600),
              'native_app_init_start': ago(540),
              'native_app_init_end': ago(500),
              'engine_attach': ago(400),
              'native_first_frame': ago(100),
              'native_splash_exit_start': ago(100),
              'native_splash_exit_end': ago(-100),
            },
            launchType: LaunchType.warm,
          ),
        ),
      )..start();
      final trace = await finish();

      expect(trace.origin, LaunchTraceOrigin.launchRequested);
      expect(trace.launchType, LaunchType.warm);
      expect(trace.processStartMs, 40);
      expect(trace.engineAttachMs, 200);
      expect(trace.markers['launch_requested'], 0);
      expect(trace.markers['native_app_init_end'], 100);
      expect(trace.markers['native_splash_exit_end'], 700);

      final native = _span(trace, 'native');
      expect(native.startOffsetMs, 40);
      expect(native.durationMs, 160);
      final appInit = _span(trace, 'native_app_init');
      expect(appInit.parentId, 'native');
      expect(appInit.startOffsetMs, 60);
      expect(appInit.durationMs, 40);
      expect(_span(trace, 'native_splash').durationMs, 700);
      final exit = _span(trace, 'native_splash_exit');
      expect(exit.parentId, 'native_splash');
      expect(exit.durationMs, 200);
      expect(LaunchTrace.fromJson(trace.toJson()).markers, trace.markers);
    });

    test('drops markers before the origin', () async {
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      tracker.seedNative(
        LaunchTimestamps(
          epochUs: {
            'engine_attach': nowUs - 100000,
            'native_app_init_start': nowUs - 150000,
          },
        ),
      );
      final trace = await finish();

      expect(trace.origin, LaunchTraceOrigin.engineAttach);
      expect(trace.markers, isNot(contains('native_app_init_start')));
      expect(trace.spans.map((s) => s.id), isNot(contains('native_app_init')));
    });

    test('records dart_main and the splash removal', () async {
      markDartMain();
      var removed = false;
      removeNativeSplash(() => removed = true);
      final trace = await finish();

      expect(removed, isTrue);
      expect(trace.markers['dart_main'], isNotNull);
      expect(trace.markers['native_splash_remove'], isNotNull);
    });
  });

  test('launchType parses prewarm and ignores unknown values', () {
    LaunchTrace parse(Object? type) => LaunchTrace.fromJson({
      'schemaVersion': 1,
      'origin': 'process_start',
      'launchType': type,
      'spans': <Object?>[],
    });

    expect(parse('prewarm').launchType, LaunchType.prewarm);
    expect(parse('lukewarm').launchType, isNull);
    expect(parse(null).launchType, isNull);
  });
}
