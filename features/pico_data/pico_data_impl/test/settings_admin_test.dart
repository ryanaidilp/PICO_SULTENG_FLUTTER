import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Images implements ImageCacheAdmin {
  int size = 500;
  int cleared = 0;

  @override
  Future<int> bytes() async => size;

  @override
  Future<void> clear() async {
    cleared++;
    size = 0;
  }
}

void main() {
  group('SettingsRepositoryImpl (C08)', () {
    test('defaults: theme system, alerts off', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsRepositoryImpl(await SharedPreferences.getInstance());
      expect(s.themeMode, PicoThemeMode.system);
      expect(s.dataUpdateAlertsWanted, isFalse);
    });

    test('saves under the contract keys and emits on change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = SettingsRepositoryImpl(prefs);
      final changed = s.themeModeChanges.first;
      await s.setThemeMode(PicoThemeMode.dark);
      expect(await changed, PicoThemeMode.dark);
      expect(prefs.getString('pico.settings.theme_mode'), 'dark');
      await s.setDataUpdateAlertsWanted(true);
      expect(prefs.getBool('pico.settings.data_update_alerts'), isTrue);
      expect(SettingsRepositoryImpl(prefs).themeMode, PicoThemeMode.dark);
    });

    test('an unknown stored value reads as the default', () async {
      SharedPreferences.setMockInitialValues({
        'pico.settings.theme_mode': 'sepia',
      });
      final s = SettingsRepositoryImpl(await SharedPreferences.getInstance());
      expect(s.themeMode, PicoThemeMode.system);
    });
  });

  test(
    'LocalDataAdmin adds the store and the image cache, and clears both',
    () async {
      final dir = Directory.systemTemp.createTempSync('pico_admin_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = SnapshotStore(Directory('${dir.path}/s'));
      await store.write('k', 'x' * 1000, DateTime.utc(2024));
      final images = _Images();
      final admin = LocalDataAdminImpl(store, images);
      expect(await admin.cachedBytes(), greaterThan(1500));
      await admin.clearAll();
      expect(await admin.cachedBytes(), 0);
      expect(images.cleared, 1);
      expect(await store.read('k'), isNull);
    },
  );
}
