import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_detail_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';

import 'harness.dart';

/// T29: the four guideline checks for both Infografis pages, in id light x1
/// and en dark x2. The images are the designed missing-image state in tests.
Future<void> guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
  expect(tester.takeException(), isNull);
}

void main() {
  final pages = <String, Widget>{
    'gallery': InfografisPage(onOpen: (_) {}),
    'detail': const InfografisDetailPage(id: 97, syncUrl: false),
  };
  for (final entry in pages.entries) {
    for (final (l, locale, dark, scale) in [
      (AppLocale.id, const Locale('id'), false, 1.0),
      (AppLocale.en, const Locale('en'), true, 2.0),
    ]) {
      final n =
          '${entry.key}, ${l.languageCode} ${dark ? 'dark' : 'light'} '
          'x${scale.toInt()}';
      testWidgets('guidelines: $n', (tester) async {
        await setup(tester, l);
        big(tester, scale == 2 ? 6000 : 3000);
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          host(
            entry.value,
            PagedContent(),
            theme: dark ? PicoTheme.dark() : PicoTheme.light(),
            scale: scale,
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        if (entry.key == 'detail') {
          // Id 97 is on page 2: the page found its item, not the not-found state.
          expect(find.text('Infografis 97'), findsWidgets);
        }
        await guidelines(tester);
        h.dispose();
        await setup(tester, AppLocale.id);
      });
    }
  }
}
