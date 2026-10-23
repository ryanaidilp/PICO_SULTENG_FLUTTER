/// Information about a connected Flutter device or emulator.
class const DeviceInfo({
  /// The device identifier used with `flutter run -d`.
  required final String id,

  /// The human-readable device name.
  required final String name,

  /// The target platform (e.g. `android-arm64`, `ios`).
  required final String platform,

  /// Whether this device is an emulator or simulator.
  required final bool isEmulator,
}) {
  /// Creates a new [DeviceInfo].
  this;

  /// Creates a [DeviceInfo] from a JSON map returned by `flutter devices --machine`.
  factory fromJson(Map<String, dynamic> json) => DeviceInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unknown Device',
    platform: json['targetPlatform'] as String? ?? 'unknown',
    isEmulator: json['emulator'] as bool? ?? false,
  );

  /// Returns a display label suitable for interactive prompts.
  String get displayLabel {
    final type = isEmulator ? 'emulator' : platform;
    return '$name ($type) - $id';
  }

  @override
  String toString() => displayLabel;
}
