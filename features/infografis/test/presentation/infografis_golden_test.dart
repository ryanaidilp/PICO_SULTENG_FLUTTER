import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_detail_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';

import 'harness.dart';

void main() {
  setUp(PicoSvgSource.clearCache);

  for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
    final n = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
    for (final detail in [false, true]) {
      testWidgets('golden ${detail ? 'detail' : 'grid'} $n', (tester) async {
        await setup(tester, AppLocale.id);
        big(tester, scale == 2 ? 2400 : 900);
        await tester.pumpWidget(
          host(
            detail
                ? const InfografisDetailPage(id: 100, syncUrl: false)
                : InfografisPage(onOpen: (_) {}),
            PagedContent(pages: 1),
            theme: dark ? PicoTheme.dark() : PicoTheme.light(),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${detail ? 'detail' : 'grid'}_$n.png'),
        );
      }, tags: ['golden']);
    }
  }
}
