// LaunchTrace v1. Contract: docs/specs/launch-trace/contract.md, ADR-036.

/// The launch phase a span belongs to.
enum LaunchPhase(
  /// Stable JSON value.
  final String wireName,
) {
  /// Process start until the Flutter engine attaches.
  native('native'),

  /// Engine attach until the launch tracker starts (Dart VM boot, `main()`,
  /// bootstrap and DI).
  engine('engine'),

  /// Blocking initializers that must finish before the app content shows.
  preLaunch('pre_launch'),

  /// Pre-launch done until the first frame of app content is drawn.
  firstFrame('first_frame'),

  /// Deferred initializers that run after the first frame.
  postLaunch('post_launch');

  /// Every phase before post-launch delays the first frame of app content.
  bool get blocksFirstFrame => this != postLaunch;
}

/// Whether a span ran alone in a queue or inside a parallel batch.
enum LaunchSpanMode() {
  sequential,
  parallel,
}

/// How a span ended.
enum LaunchSpanStatus() {
  ok,
  failed,
  timeout,
}

/// Cold: the process started for this launch. Warm: the process was
/// already alive, or the activity restored saved state (Android). Prewarm:
/// iOS started the process ahead of the launch.
enum LaunchType() {
  cold,
  warm,
  prewarm;

  /// `null` for a missing or unknown value, so a newer recorder's value
  /// never breaks this reader.
  static LaunchType? fromWire(Object? wire) {
    for (final type in values) {
      if (type.name == wire) return type;
    }
    return null;
  }
}

/// The clock zero every offset in a [LaunchTrace] is measured from.
enum LaunchTraceOrigin(
  /// Stable JSON value.
  final String wireName,
) {
  /// The launch request (Android 13+). Earlier than process start.
  launchRequested('launch_requested'),
  processStart('process_start'),
  engineAttach('engine_attach'),
  dartStart('dart_start'),
}

T _byWire<T extends Enum>(List<T> values, Object? wire, String Function(T) f) {
  for (final value in values) {
    if (f(value) == wire) return value;
  }
  throw FormatException('Unknown $T value: $wire');
}

double? _ms(Object? value) => (value as num?)?.toDouble();

/// One timed step of the launch. Offsets and durations are fractional
/// milliseconds (microsecond resolution) from [LaunchTrace.origin].
class const LaunchSpan({
  /// Unique within one trace. Phase spans use the phase wire name.
  required final String id,
  required final String name,
  required final LaunchPhase phase,
  required final double startOffsetMs,
  required final double durationMs,
  required final bool blocksFirstFrame,

  /// Id of the enclosing span, or `null` for a root span.
  final String? parentId,
  final LaunchSpanMode mode = LaunchSpanMode.sequential,

  /// Shared by every span of one parallel batch; `null` when sequential.
  final String? group,
  final LaunchSpanStatus status = LaunchSpanStatus.ok,
}) {
  /// Parses one entry of the `spans` array.
  factory fromJson(Map<String, Object?> json) => LaunchSpan(
    id: json['id']! as String,
    parentId: json['parentId'] as String?,
    name: json['name']! as String,
    phase: _byWire(LaunchPhase.values, json['phase'], (p) => p.wireName),
    startOffsetMs: _ms(json['startOffsetMs'])!,
    durationMs: _ms(json['durationMs'])!,
    mode: _byWire(LaunchSpanMode.values, json['mode'], (m) => m.name),
    group: json['group'] as String?,
    blocksFirstFrame: json['blocksFirstFrame']! as bool,
    status: _byWire(LaunchSpanStatus.values, json['status'], (s) => s.name),
  );

  double get endOffsetMs => startOffsetMs + durationMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'parentId': parentId,
    'name': name,
    'phase': phase.wireName,
    'startOffsetMs': startOffsetMs,
    'durationMs': durationMs,
    'mode': mode.name,
    'group': group,
    'blocksFirstFrame': blocksFirstFrame,
    'status': status.name,
  };
}

/// A structured timeline of one app launch: spans plus milestone markers.
class const LaunchTrace({
  required final LaunchTraceOrigin origin,

  /// Sorted by [LaunchSpan.startOffsetMs].
  required final List<LaunchSpan> spans,

  /// Wall-clock time of [origin] in ms since the Unix epoch. Only for
  /// lining the trace up with other timestamped data; never subtract it
  /// from another wall-clock value to measure a duration.
  final int? originEpochMs,

  /// `null` when the platform did not report it.
  final LaunchType? launchType,

  /// Markers, in ms from [origin]; `null` when not reached or not known.
  final double? processStartMs,
  final double? engineAttachMs,
  final double? firstFrameMs,

  /// Post-launch finished: every startup step is done.
  final double? interactiveMs,

  /// Markers without a field of their own, by wire key, in ms from
  /// [origin]. Kept so a reader shows markers added after it was written.
  final Map<String, double> otherMarkers = const {},
}) {
  /// Parses a trace written by [toJson]. Throws [FormatException] for any
  /// other `schemaVersion`.
  factory fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported LaunchTrace schemaVersion: $version');
    }
    final markers = (json['markers'] as Map?)?.cast<String, Object?>() ?? {};
    return LaunchTrace(
      origin: _byWire(
        LaunchTraceOrigin.values,
        json['origin'],
        (o) => o.wireName,
      ),
      originEpochMs: json['originEpochMs'] as int?,
      launchType: LaunchType.fromWire(json['launchType']),
      processStartMs: _ms(markers['process_start']),
      engineAttachMs: _ms(markers['engine_attach']),
      firstFrameMs: _ms(markers['first_frame']),
      interactiveMs: _ms(markers['interactive']),
      otherMarkers: {
        for (final MapEntry(:key, :value) in markers.entries)
          if (!_namedMarkers.contains(key) && value is num)
            key: value.toDouble(),
      },
      spans: [
        for (final span in json['spans']! as List)
          LaunchSpan.fromJson((span as Map).cast<String, Object?>()),
      ],
    );
  }

  static const int schemaVersion = 1;

  static const _namedMarkers = {
    'process_start',
    'engine_attach',
    'first_frame',
    'interactive',
  };

  /// Every known marker by wire key, in ms from [origin].
  Map<String, double> get markers => {
    'process_start': ?processStartMs,
    'engine_attach': ?engineAttachMs,
    'first_frame': ?firstFrameMs,
    'interactive': ?interactiveMs,
    ...otherMarkers,
  };

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'origin': origin.wireName,
    'originEpochMs': originEpochMs,
    'launchType': launchType?.name,
    'markers': markers,
    'spans': [for (final span in spans) span.toJson()],
  };
}
