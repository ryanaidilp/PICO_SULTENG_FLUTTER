import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/ui/pages/informasi_page.dart';
import 'package:informasi/src/presentation/ui/pages/tip_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'harness.dart';

void main() {
  setUp(PicoSvgSource.clearCache);

  final cases = <(String, Widget, bool, double, double)>[
    ('hub_light_x1', InformasiPage(onOpen: (_) {}), false, 1, 1100),
    ('tip_cuci_dark_x1', const TipPage(slug: 'cuci-tangan'), true, 1, 1100),
    ('tip_gejala_light_x2', const TipPage(slug: 'gejala'), false, 2, 7000),
  ];
  for (final (name, page, dark, scale, h) in cases) {
    testWidgets('golden $name', (tester) async {
      await setup(tester, AppLocale.id);
      big(tester, h);
      await tester.pumpWidget(
        host(
          page,
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: scale,
        ),
      );
      await settle(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }, tags: ['golden']);
  }
}
