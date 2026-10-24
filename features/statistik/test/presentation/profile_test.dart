import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/province_math.dart';
import 'package:statistik/src/l10n/translations.g.dart';

import '../support.dart';
import 'area_page_test.dart' as page;

void main() {
  goldens();
  CountingCases repo() =>
      CountingCases(sultengSeries(), provinces: provinceSummaries());

  group('orderProvinces', () {
    final all = provinceSummaries().rightOrNull!.data;

    test('34 provinces, Sulawesi Tengah first, the rest by name', () {
      final rows = orderProvinces(all);
      expect(rows, hasLength(34));
      expect(rows.first.name, 'Sulawesi Tengah');
      expect(rows[1].name, 'Aceh');
      final rest = [for (final r in rows.skip(1)) r.name];
      expect(rest, [...rest]..sort(), reason: 'alphabetical after the pin');
    });

    test('search is accent and case insensitive', () {
      expect(orderProvinces(all, query: 'SULAWESI').length, 5);
      expect(
        orderProvinces(all, query: '  sulawesi t ').first.name,
        'Sulawesi Tengah',
      );
      expect(
        orderProvinces(all, query: 'kalimantan u').single.name,
        'Kalimantan Utara',
      );
      expect(orderProvinces(all, query: 'zzz'), isEmpty);
    });
  });

  testWidgets('picker: search, pinned first, pick opens that province', (
    tester,
  ) async {
    await page.setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigated = <String>[];
    await tester.pumpWidget(
      page.host(
        repo(),
        const AreaQuery(area: AreaRef.province('72')),
        navigated: navigated,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti provinsi'));
    await tester.pumpAndSettle();
    // The first row is the pinned, selected one, with its cumulative positive.
    expect(find.text('Cari provinsi'), findsOneWidget);
    final rows = find.descendant(
      of: find.byType(ListView).last,
      matching: find.textContaining('Positif kumulatif'),
    );
    expect(rows, findsWidgets);
    expect(find.text('Positif kumulatif: 72.000'), findsOneWidget);
    final firstY = tester.getTopLeft(find.text('Sulawesi Tengah').last).dy;
    final acehY = tester.getTopLeft(find.text('Aceh')).dy;
    expect(firstY, lessThan(acehY));
    await tester.enterText(find.byType(TextField).last, 'bali');
    await tester.pumpAndSettle();
    expect(find.text('Bali'), findsOneWidget);
    expect(find.text('Aceh'), findsNothing);
    await tester.tap(find.text('Bali'));
    await tester.pumpAndSettle();
    expect(navigated.last, '/statistik?level=province&id=51');
    await tester.pumpAndSettle();
    expect(
      find.text('Wilayah: Bali'),
      findsNothing,
    ); // title is the series name
  });

  testWidgets('picker: no match shows the empty state', (tester) async {
    await page.setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      page.host(repo(), const AreaQuery(area: AreaRef.province('72'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti provinsi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada provinsi'), findsOneWidget);
  });

  group('ODP and PDP', () {
    testWidgets('a day with no data shows the no-data state and its reason, '
        'never 0 bars', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        page.host(repo(), const AreaQuery(area: AreaRef.province('72'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('ODP dan PDP'), findsOneWidget);
      expect(
        find.text('Tidak ada data ODP/PDP untuk tanggal ini'),
        findsOneWidget,
      );
      expect(
        find.text('ODP dan PDP tidak punya sumber data setelah awal pandemi.'),
        findsOneWidget,
      );
      expect(find.text('ODP aktif'), findsNothing);
    });

    testWidgets('an early range shows the four bars', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        page.host(
          repo(),
          AreaQuery(
            area: const AreaRef.province('72'),
            from: DateTime(2020, 3, 2),
            to: DateTime(2020, 4, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ODP aktif'), findsOneWidget);
      expect(find.text('PDP selesai'), findsOneWidget);
      expect(
        find.text('Tidak ada data ODP/PDP untuk tanggal ini'),
        findsNothing,
      );
      expect(find.text('Pada 1 Apr 2020'), findsOneWidget);
    });

    testWidgets('national page has no ODP/PDP section', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(page.host(repo(), nationalQuery));
      await tester.pumpAndSettle();
      expect(find.text('ODP dan PDP'), findsNothing);
      expect(find.text('Jenis kelamin dan usia'), findsNothing);
    });
  });

  group('gender (Sulawesi Tengah only)', () {
    testWidgets('latest recorded data with no date, groups and bars', (
      tester,
    ) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 5200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        page.host(repo(), const AreaQuery(area: AreaRef.province('72'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jenis kelamin dan usia'), findsOneWidget);
      expect(
        find.textContaining('Data terakhir yang tercatat'),
        findsOneWidget,
      );
      expect(find.text('Laki-laki'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('0-14 tahun'), findsNWidgets(2));
      expect(find.text('55 tahun ke atas'), findsNWidgets(2));
      // The API's `day` index is never shown as a date.
      expect(find.textContaining('799'), findsNothing);
    });

    testWidgets('another province has no gender section', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final other = CountingCases(
        sultengSeries(area: const AreaRef.province('11')),
        provinces: provinceSummaries(),
      );
      await tester.pumpWidget(
        page.host(other, const AreaQuery(area: AreaRef.province('11'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jenis kelamin dan usia'), findsNothing);
      expect(find.text('ODP dan PDP'), findsOneWidget);
    });

    testWidgets('no gender data shows a sentence, never zero bars', (
      tester,
    ) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 5200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        page.host(
          repo(),
          const AreaQuery(area: AreaRef.province('72')),
          stats: FakeStatsRepository()..latestGender = fakeFailure(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada data jenis kelamin.'), findsOneWidget);
      expect(find.text('Laki-laki'), findsNothing);
    });
  });

  testWidgets('english and text scale 2.0 without overflow', (tester) async {
    await page.setup(tester, AppLocale.en);
    tester.view.physicalSize = const Size(412, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      page.host(
        repo(),
        const AreaQuery(area: AreaRef.province('72')),
        scale: 2,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Change province'), findsOneWidget);
    expect(find.text('No ODP/PDP data for this date'), findsOneWidget);
    expect(find.text('Latest recorded data'), findsNothing); // joined line
    expect(find.textContaining('Latest recorded data'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await page.setup(tester, AppLocale.id);
  });
}

void goldens() {
  for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
    final n = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
    testWidgets('golden sulteng profile $n', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = Size(412, scale == 2 ? 11000 : 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        page.host(
          CountingCases(sultengSeries(), provinces: provinceSummaries()),
          AreaQuery(
            area: const AreaRef.province('72'),
            from: DateTime(2020, 3, 2),
            to: DateTime(2020, 4, 1),
          ),
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
        matchesGoldenFile('goldens/profile_$n.png'),
      );
    }, tags: ['golden']);
  }
}
