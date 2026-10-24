import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_detail_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';

import 'harness.dart';

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  for (final (dark, scale) in [(false, 1.0), (true, 1.0), (false, 2.0)]) {
    final n = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
    testWidgets('golden detail $n', (tester) async {
      await setup(tester, AppLocale.id);
      big(tester, scale == 2 ? 3600 : 1400);
      await tester.runAsync(
        () => WeaveShaderCache.instance.warmUp(
          dark ? Brightness.dark : Brightness.light,
          1,
        ),
      );
      await tester.pumpWidget(
        host(
          const HospitalDetailPage(code: '7271025'),
          directory(),
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
        matchesGoldenFile('goldens/detail_$n.png'),
      );
    }, tags: ['golden']);
  }
}
