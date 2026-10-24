/// A single named timing point or duration trace during app launch.
class const MetricTrace({
  required final String name,
  required final int timestampMillis,

  /// Set only for duration traces recorded via `recordDuration`.
  final int? durationMilliseconds,
}) {
  @override
  String toString() =>
      "{'name': $name, 'timestampMillis': $timestampMillis, "
      "'durationMs': $durationMilliseconds}";
}

/// Aggregate timing data captured over the two-phase app launch.
///
/// Internal to `app_launch_tracker_impl`. Not exported from the barrel file.
class const AppLaunchMetrics({
  /// Elapsed ms from tracker start to pre-launch completing.
  final int? preLaunchMs,

  /// Elapsed ms from tracker start to first frame on screen.
  final int? firstFrameMs,

  /// Duration of the post-launch phase in ms.
  final int? postLaunchMs,

  /// Total ms from native process start to post-launch completing.
  final int? totalStartupMs,

  /// Native process start timestamp in ms since epoch (from platform channel).
  final int? nativeStartMs,

  /// Flutter engine attach timestamp in ms since epoch (from platform channel).
  final int? hostStartMs,

  /// Named step timestamps recorded via `recordStep`.
  final List<MetricTrace> steps = const [],

  /// Duration traces recorded via `recordDuration`.
  final List<MetricTrace> traces = const [],
});
