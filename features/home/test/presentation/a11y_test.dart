import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_test/flutter_test.dart';
import 'package:home/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';

import 'home_page_test.dart' show host, repo, setup;

/// T29: Beranda, the four guideline checks in id light x1, en dark x2 and
/// en light x1.5.
void main() {
  for (final (l, locale, dark, scale) in [
    (AppLocale.id, const Locale('id'), false, 1.0),
    (AppLocale.en, const Locale('en'), true, 2.0),
    // The hero's white label on the light end of its gradient.
    (AppLocale.en, const Locale('en'), false, 1.5),
  ]) {
    testWidgets(
      'guidelines: beranda, ${l.languageCode} ${dark ? 'dark' : 'light'} '
      'x$scale',
      (tester) async {
        await setup(tester, l);
        final h = tester.ensureSemantics();
        tester.view.physicalSize = Size(412, scale > 1 ? 9000 : 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            repo(),
            // Three banners whose images never load: the designed cards.
            content: FakeContentRepository()
              ..banners = fakeSnapshot([
                for (var i = 1; i <= 3; i++)
                  Banner(
                    id: i,
                    title: 'Kabar $i',
                    link: i == 1 ? Uri.parse('https://a.example/1') : null,
                    imageUrl: 'https://banuacoders.com/storage/b$i.jpg',
                  ),
              ]),
            locale: locale,
            scale: scale,
            theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
        expect(tester.takeException(), isNull);
        h.dispose();
        await setup(tester, AppLocale.id);
      },
    );
  }
}
