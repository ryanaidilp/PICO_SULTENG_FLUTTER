import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/l10n/translations.g.dart';

import '../support.dart';
import 'area_page_test.dart' as area;
import 'kabupaten_test.dart' as kab;
import 'rt_test.dart' as rt;
import 'tests_test.dart' as tes;

/// T29: the four guideline checks for every Statistik page, in id light x1 and
/// en dark x2, plus the province picker.
Future<void> guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
  expect(tester.takeException(), isNull);
}

typedef _Build = Widget Function(ThemeData theme, double scale, Locale locale);

void main() {
  final pages = <String, _Build>{
    'kabupaten list': (theme, scale, locale) =>
        kab.host(kab.cubit(), theme: theme, scale: scale, locale: locale),
    'kabupaten area page': (theme, scale, locale) => area.host(
      CountingCases(
        sultengSeries(area: const AreaRef.regency('7271')),
        provinces: provinceSummaries(),
      ),
      const AreaQuery(area: AreaRef.regency('7271')),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'province area page': (theme, scale, locale) => area.host(
      CountingCases(sultengSeries(), provinces: provinceSummaries()),
      const AreaQuery(area: AreaRef.province('72')),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'national area page': (theme, scale, locale) => area.host(
      CountingCases(
        sultengSeries(area: const AreaRef.national()),
        provinces: provinceSummaries(),
      ),
      const AreaQuery(area: AreaRef.national()),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'rt page': (theme, scale, locale) => rt.host(
      rt.RtCases(rt.nationalRt()),
      const AreaRef.national(),
      theme: theme,
      scale: scale,
      locale: locale,
    ),
    'tes page': (theme, scale, locale) =>
        tes.host(tes.stats(), theme: theme, scale: scale, locale: locale),
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
        await area.setup(tester, l);
        tester.view.physicalSize = Size(412, scale == 2 ? 14000 : 9000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          entry.value(
            dark ? PicoTheme.dark() : PicoTheme.light(),
            scale,
            locale,
          ),
        );
        await tester.pumpAndSettle();
        await guidelines(tester);
        h.dispose();
        await area.setup(tester, AppLocale.id);
      });
    }
  }

  for (final (l, locale, dark, scale) in [
    (AppLocale.id, const Locale('id'), false, 1.0),
    (AppLocale.en, const Locale('en'), true, 2.0),
  ]) {
    testWidgets('guidelines: province picker, ${l.languageCode}, x$scale', (
      tester,
    ) async {
      await area.setup(tester, l);
      tester.view.physicalSize = Size(412, scale == 2 ? 6000 : 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        area.host(
          CountingCases(sultengSeries(), provinces: provinceSummaries()),
          const AreaQuery(area: AreaRef.province('72')),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: scale,
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l == AppLocale.id ? 'Ganti provinsi' : 'Change province'),
      );
      await tester.pumpAndSettle();
      await guidelines(tester);
      h.dispose();
      await area.setup(tester, AppLocale.id);
    });
  }
}
