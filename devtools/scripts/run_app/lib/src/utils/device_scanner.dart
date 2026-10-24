import 'dart:convert';
import 'dart:io';

import 'package:run_app/src/models/device_info.dart';

/// Scans for connected Flutter devices by running `flutter devices --machine`.
class DeviceScanner() {
  /// Returns the list of currently connected devices and emulators.
  ///
  /// Runs `flutter devices --machine` and parses the JSON array response.
  /// Returns an empty list when no devices are connected or the command fails.
  static Future<List<DeviceInfo>> getDevices() async {
    final result = await Process.run('flutter', [
      'devices',
      '--machine',
    ], runInShell: Platform.isWindows);

    if (result.exitCode != 0) {
      return [];
    }

    final output = result.stdout.toString().trim();
    if (output.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(output);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DeviceInfo.fromJson)
          .toList();
    } on FormatException {
      return [];
    }
  }
}
