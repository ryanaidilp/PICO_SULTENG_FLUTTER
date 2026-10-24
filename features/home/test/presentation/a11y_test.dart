import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_test/flutter_test.dart';
import 'package:home/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'home_page_test.dart' show host, repo, setup;

/// T29: Beranda, the four guideline checks in id light x1 and en dark x2.
void main() {
  for (final (l, locale, dark, scale) in [
    (AppLocale.id, const Locale('id'), false, 1.0),
    (AppLocale.en, const Locale('en'), true, 2.0),
  ]) {
    testWidgets(
      'guidelines: beranda, ${l.languageCode} ${dark ? 'dark' : 'light'} '
      'x${scale.toInt()}',
      (tester) async {
        await setup(tester, l);
        final h = tester.ensureSemantics();
        tester.view.physicalSize = Size(412, scale == 2 ? 9000 : 3000);
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
        await hiDpi(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        h.dispose();
        await setup(tester, AppLocale.id);
      },
    );
  }
}

/// Renders at twice the density before the contrast check: at 1x the 12 to
/// 16 px text of a Linux software raster has no pixel dark enough, so the
/// guideline measures its anti-aliasing and not its colour (CI failed at 1.4:1
/// on text that is 7:1). The logical size does not change.
Future<void> hiDpi(WidgetTester tester) async {
  final view = tester.view;
  if (view.devicePixelRatio >= 2) return;
  view.physicalSize = view.physicalSize * 2;
  view.devicePixelRatio = 2;
  await tester.pumpAndSettle();
}
