import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:vaksin/src/l10n/translations.g.dart';

import 'harness.dart';

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  for (final dark in [false, true]) {
    testWidgets('golden coverage ${dark ? 'dark' : 'light'} x2', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester, 6200);
      await tester.runAsync(
        () => WeaveShaderCache.instance.warmUp(
          dark ? Brightness.dark : Brightness.light,
          1,
        ),
      );
      await tester.pumpWidget(
        host(
          stats(),
          directory(),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/vaksin_${dark ? 'dark' : 'light'}_x2.png'),
      );
    }, tags: ['golden']);
  }

  testWidgets('golden locations light x1', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 900);
    await tester.pumpWidget(host(stats(), directory()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lokasi'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/vaksin_locations_light.png'),
    );
  }, tags: ['golden']);
}
