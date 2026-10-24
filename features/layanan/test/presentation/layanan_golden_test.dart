import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_list_page.dart';
import 'package:layanan/src/presentation/ui/pages/layanan_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  for (final dark in [false, true]) {
    final n = dark ? 'dark' : 'light';
    testWidgets('golden hub $n', (tester) async {
      await setup(tester, AppLocale.id);
      big(tester, 700);
      await tester.pumpWidget(
        host(
          LayananPage(onOpen: (_) {}),
          directory(),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
        ),
      );
      await _settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hub_$n.png'),
      );
    }, tags: ['golden']);

    testWidgets('golden list $n x2', (tester) async {
      await setup(tester, AppLocale.id);
      big(tester, 2600);
      await tester.pumpWidget(
        host(
          const HospitalListPage(),
          directory(),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: 2,
        ),
      );
      await _settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/list_${n}_x2.png'),
      );
    }, tags: ['golden']);
  }
}
