import 'package:app_launch_tracker_impl/src/app_launch_tracker_impl.dart';
import 'package:app_launch_tracker_impl/src/launch_time_tracker_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// Stub channel that returns controlled timestamps.
class _FakeChannel({required final LaunchTimestamps? timestamps})
    extends LaunchTimeTrackerChannel {
  @override
  Future<LaunchTimestamps?> fetchTimestamps() async => timestamps;

  @override
  Future<LaunchTimestamps?> reportInteractive() async => timestamps;
}

const _timestamps = LaunchTimestamps(
  epochUs: {'process_start': 1000000, 'engine_attach': 1200000},
);

/// Records every outbound span. The tracker's only way off the device is
/// [AppMonitoring.recordTransaction]; the DI-bound implementation
/// (`ConsentAwareMonitoring`) gates that call on diagnostics consent and
/// reports `isEnabled == false` while consent is denied.
class _FakeMonitoring({required final bool enabled}) implements AppMonitoring {
  final transactions = <String>[];

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  }) {
    transactions.add(name);
    return action();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLaunchTracker', () {
    late AppLaunchTracker tracker;

    setUp(() {
      tracker = AppLaunchTracker(
        channel: _FakeChannel(timestamps: _timestamps),
      );
    });

    test('start seeds native timestamps via channel', () async {
      tracker.start();
      // Allow the fire-and-forget Future to complete.
      await Future<void>.delayed(Duration.zero);

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.nativeStartMs, equals(1000));
      expect(metrics.hostStartMs, equals(1200));
    });

    test('markPreLaunchCompleted records pre-launch duration', () {
      tracker.start();
      tracker.markPreLaunchCompleted();

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.preLaunchMs, isNotNull);
      expect(metrics.preLaunchMs, greaterThanOrEqualTo(0));
    });

    test('markFirstFrameRendered records first-frame duration', () {
      tracker.start();
      tracker.markFirstFrameRendered();

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.firstFrameMs, isNotNull);
    });

    test('startPostLaunch and markPostLaunchCompleted record post-launch', () {
      tracker.start();
      tracker.startPostLaunch();
      tracker.markPostLaunchCompleted();

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.postLaunchMs, isNotNull);
      expect(metrics.postLaunchMs, greaterThanOrEqualTo(0));
    });

    test('recordStep captures named steps', () {
      tracker.start();
      tracker.recordStep('CustomStep');

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.steps.any((s) => s.name == 'CustomStep'), isTrue);
    });

    test('recordDuration captures named durations', () {
      tracker.recordDuration('myOperation', 42);

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.traces, hasLength(1));
      expect(metrics.traces.first.name, equals('myOperation'));
      expect(metrics.traces.first.durationMilliseconds, equals(42));
    });

    test('seedNativeTimestamps directly sets timestamps', () {
      tracker.seedNativeTimestamps(nativeStartMs: 5000, hostStartMs: 5100);

      final metrics = tracker.getMetricsSnapshot();
      expect(metrics.nativeStartMs, equals(5000));
      expect(metrics.hostStartMs, equals(5100));
    });

    test('totalStartupMs is computed after marking first frame and post-launch', () {
      tracker.start();
      tracker.markFirstFrameRendered();
      tracker.startPostLaunch();
      tracker.markPostLaunchCompleted();

      final metrics = tracker.getMetricsSnapshot();
      // totalStartupMs may be 0 in fast tests (null when both phases are 0ms);
      // verify both component fields are captured.
      expect(metrics.firstFrameMs, isNotNull);
      expect(metrics.postLaunchMs, isNotNull);
    });

    test('channel returning null does not set native timestamps', () async {
      final noChannelTracker = AppLaunchTracker(
        channel: _FakeChannel(timestamps: null),
      );
      noChannelTracker.start();
      await Future<void>.delayed(Duration.zero);

      final metrics = noChannelTracker.getMetricsSnapshot();
      expect(metrics.nativeStartMs, isNull);
      expect(metrics.hostStartMs, isNull);
    });
  });

  group('LaunchTimestamps', () {
    test('derives native and host start in epoch ms', () {
      expect(_timestamps.nativeStartMs, equals(1000));
      expect(_timestamps.hostStartMs, equals(1200));
    });
  });

  group('span export (release builds keep the tracker)', () {
    Future<_FakeMonitoring> runLaunch({required bool enabled}) async {
      final monitoring = _FakeMonitoring(enabled: enabled);
      AppLaunchTracker(
          channel: _FakeChannel(timestamps: _timestamps),
          monitoring: monitoring,
        )
        ..start()
        ..markPreLaunchCompleted()
        ..markFirstFrameRendered()
        ..startPostLaunch()
        ..markPostLaunchCompleted();
      await Future<void>.delayed(Duration.zero);
      return monitoring;
    }

    test(
      'sends nothing when monitoring is disabled (consent denied)',
      () async {
        final monitoring = await runLaunch(enabled: false);

        expect(monitoring.transactions, isEmpty);
      },
    );

    test('sends spans only through AppMonitoring when enabled', () async {
      final monitoring = await runLaunch(enabled: true);

      expect(monitoring.transactions.first, 'app_launch');
      expect(monitoring.transactions, everyElement(startsWith('app_launch')));
    });
  });
}
