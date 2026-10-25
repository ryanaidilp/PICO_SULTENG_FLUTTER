import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/ui/pages/informasi_page.dart';
import 'package:informasi/src/presentation/ui/pages/tentang_page.dart';
import 'package:informasi/src/presentation/ui/pages/tip_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';

import 'harness.dart' as h;
import 'tentang_test.dart' as t;

/// T29: the four guideline checks for the Info hub, a tip and Tentang, in id
/// light x1 and en dark x2.
Future<void> guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
  expect(tester.takeException(), isNull);
}

void main() {
  final pages = <String, Widget Function(ThemeData, double, Locale)>{
    'info hub': (theme, scale, locale) => h.host(
      InformasiPage(onOpen: (_) {}),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'tip cuci tangan': (theme, scale, locale) => h.host(
      const TipPage(slug: 'cuci-tangan'),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'tip gejala': (theme, scale, locale) => h.host(
      const TipPage(slug: 'gejala'),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'tentang': (theme, scale, locale) =>
        t.host(const TentangPage(), theme: theme, scale: scale, locale: locale),
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
        await h.setup(tester, l);
        h.big(tester, scale == 2 ? 16000 : 9000);
        final sem = tester.ensureSemantics();
        await tester.pumpWidget(
          entry.value(
            dark ? PicoTheme.dark() : PicoTheme.light(),
            scale,
            locale,
          ),
        );
        await h.settle(tester);
        await guidelines(tester);
        sem.dispose();
        await h.setup(tester, AppLocale.id);
      });
    }
  }
}
