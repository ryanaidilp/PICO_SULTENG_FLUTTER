import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart'
    show PicoSvgSource, WeaveShaderCache;

import 'app_shell_test.dart' show pumpApp;

// Goldens live in their own file: a brand SVG future started in another test's
// fake-async zone never completes here.
void main() {
  setUp(() {
    PicoSvgSource.clearCache();
    WeaveShaderCache.instance.clear();
  });

  for (final dark in [false, true]) {
    testWidgets('shell golden ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        settings: FakeSettingsRepository()
          ..setThemeMode(dark ? PicoThemeMode.dark : PicoThemeMode.light),
      );
      // The placeholder illustration decodes through real I/O.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/shell_${dark ? 'dark' : 'light'}.png'),
      );
    }, tags: ['golden']);
  }
}
