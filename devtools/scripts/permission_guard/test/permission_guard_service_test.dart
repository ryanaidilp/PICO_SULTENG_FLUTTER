import 'dart:io';

import 'package:permission_guard/permission_guard.dart';
import 'package:test/test.dart';

void main() {
  group('PermissionGuardService baseline', () {
    late Directory tempDir;
    late PermissionGuardService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('permission_guard_test_');
      service = PermissionGuardService(rootPath: tempDir.path);
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('saves and loads android baseline round-trip', () async {
      final permissions = [
        'android.permission.CAMERA',
        'android.permission.INTERNET',
      ];
      final baselinePath = '${tempDir.path}/android.txt';
      await service.saveBaseline(permissions, baselinePath);
      final loaded = await service.loadBaseline(baselinePath);
      expect(loaded, equals(permissions));
    });

    test('returns empty list when baseline does not exist', () async {
      final loaded = await service.loadBaseline(
        '${tempDir.path}/nonexistent.txt',
      );
      expect(loaded, isEmpty);
    });

    test('detects added permissions in diff', () {
      final current = {
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
      };
      final baseline = {'android.permission.CAMERA'};
      final diff = service.diff(current: current, baseline: baseline);
      expect(diff.added, equals({'android.permission.RECORD_AUDIO'}));
      expect(diff.removed, isEmpty);
    });

    test('detects removed permissions in diff', () {
      final current = {'android.permission.CAMERA'};
      final baseline = {
        'android.permission.CAMERA',
        'android.permission.INTERNET',
      };
      final diff = service.diff(current: current, baseline: baseline);
      expect(diff.removed, equals({'android.permission.INTERNET'}));
      expect(diff.added, isEmpty);
    });
  });

  group('IosPermissionService.extractUsageDescriptionKeys', () {
    const plistXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSCameraUsageDescription</key>
  <string>We need camera access</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>We need mic access</string>
  <key>CFBundleIdentifier</key>
  <string>com.example.app</string>
</dict>
</plist>''';

    test(
      'extracts NSCameraUsageDescription and NSMicrophoneUsageDescription',
      () {
        final keys = IosPermissionService.extractUsageDescriptionKeys(plistXml);
        expect(keys, contains('NSCameraUsageDescription'));
        expect(keys, contains('NSMicrophoneUsageDescription'));
      },
    );

    test('does not extract CFBundleIdentifier', () {
      final keys = IosPermissionService.extractUsageDescriptionKeys(plistXml);
      expect(keys, isNot(contains('CFBundleIdentifier')));
    });
  });
}
