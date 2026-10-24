import 'package:app_launch_tracker_impl/src/launch_trace.dart';
import 'package:flutter/services.dart';

/// Dart wrapper around the native `com.archipelago/launch_time_tracker`
/// method channel.
class const LaunchTimeTrackerChannel() {
  static const MethodChannel _channel = MethodChannel(
    'com.archipelago/launch_time_tracker',
  );

  /// The native milestones known so far, or `null` when the plugin is
  /// missing (unit tests, unsupported platforms).
  Future<LaunchTimestamps?> fetchTimestamps() => _call('getStartupTimestamps');

  /// Tells the platform the app is interactive (Android
  /// `reportFullyDrawn`, iOS os_signpost), then returns the milestones.
  Future<LaunchTimestamps?> reportInteractive() => _call('reportInteractive');

  Future<LaunchTimestamps?> _call(String method) async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(method);
      return raw == null ? null : LaunchTimestamps.fromNative(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// Native launch milestones, as wall-clock µs since the Unix epoch.
class const LaunchTimestamps({
  /// Marker name to wall-clock µs since the Unix epoch.
  required final Map<String, int> epochUs,
  final LaunchType? launchType,
}) {
  /// Places the native monotonic times on the wall clock with the one
  /// paired sample (`monoNowMs`, `epochNowMs`) the platform read together.
  /// Gaps between native markers stay pure monotonic differences.
  factory fromNative(Map<String, Object?> raw) {
    final monoNow = raw['monoNowMs'];
    final epochNow = raw['epochNowMs'];
    final markers = raw['markers'];
    if (monoNow is! num || epochNow is! num || markers is! Map) {
      return const LaunchTimestamps(epochUs: {});
    }
    return LaunchTimestamps(
      epochUs: {
        for (final MapEntry(:key, :value) in markers.entries)
          if (key is String && value is num)
            key: ((epochNow - (monoNow - value)) * 1000).round(),
      },
      launchType: LaunchType.fromWire(raw['launchType']),
    );
  }

  /// Process creation time in ms since the Unix epoch.
  int? get nativeStartMs => _ms('process_start');

  /// Flutter engine attach time in ms since the Unix epoch.
  int? get hostStartMs => _ms('engine_attach');

  int? _ms(String key) {
    final us = epochUs[key];
    return us == null ? null : us ~/ 1000;
  }
}
