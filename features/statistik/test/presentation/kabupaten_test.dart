import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/regency_math.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/regencies_cubit.dart';
import 'package:statistik/src/presentation/ui/pages/kabupaten_page.dart';
import 'package:statistik/src/presentation/ui/widgets/regency_widgets.dart';

import '../support.dart';
import 'area_page_test.dart' as page;

const _names = {
  '7201': 'Banggai Kepulauan',
  '7202': 'Banggai',
  '7203': 'Morowali',
  '7204': 'Poso',
  '7205': 'Donggala',
  '7206': 'Tolitoli',
  '7207': 'Buol',
  '7208': 'Parigi Moutong',
  '7209': 'Tojo Una-Una',
  '7210': 'Sigi',
  '7211': 'Banggai Laut',
  '7212': 'Morowali Utara',
  '7271': 'Kota Palu',
};

AreaSummary summary(String code, String name, int positive, int daily) =>
    AreaSummary(
      area: AreaRef.regency(code),
      name: name,
      latest: CaseDay(
        date: DateTime(2024, 1, 14),
        daily: CaseCounts(
          positive: daily,
          recovered: 0,
          deceased: 0,
          active: 0,
        ),
        cumulative: CaseCounts(
          positive: positive,
          recovered: 0,
          deceased: 0,
          active: 0,
        ),
      ),
    );

List<AreaSummary> all13({String? except}) => [
  for (final (i, e) in _names.entries.indexed)
    if (e.key != except) summary(e.key, e.value, 1000 + i * 100, i - 3),
];

List<Regency> names() => [
  for (final e in _names.entries) Regency(code: e.key, name: e.value),
];

Widget host(
  RegenciesCubit cubit, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
  List<String>? opened,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? PicoTheme.light(),
  locale: locale,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('id'), Locale('en')],
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: w!,
  ),
  home: TranslationProvider(
    child: Scaffold(
      body: BlocProvider.value(
        value: cubit,
        child: KabupatenPage(onOpen: (p) => opened?.add(p)),
      ),
    ),
  ),
);

RegenciesCubit cubit({List<AreaSummary>? summaries, bool offline = false}) =>
    RegenciesCubit(
      FakeCaseRepository(
        regencies: offline ? fakeFailure() : fakeSnapshot(summaries ?? all13()),
      ),
      FakeDirectoryRepository()..regencies = fakeSnapshot(names()),
    );

void main() {
  group('orderRegencies', () {
    test('by value high to low, by name, missing ones last', () {
      final s = all13(except: '7271');
      final byValue = orderRegencies(
        names(),
        s,
        metric: CaseMetric.positive,
        sort: RegencySort.value,
      );
      expect(byValue.first.regency.name, 'Morowali Utara');
      expect(byValue.last.regency.name, 'Kota Palu');
      expect(byValue.last.summary, isNull);
      final byName = orderRegencies(
        names(),
        s,
        metric: CaseMetric.positive,
        sort: RegencySort.name,
      );
      expect(byName.first.regency.name, 'Banggai');
      expect(byName[1].regency.name, 'Banggai Kepulauan');
    });
  });

  testWidgets('13 rows, one semantics node each, sorted by value then name', (
    tester,
  ) async {
    await page.setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = tester.ensureSemantics();
    final opened = <String>[];
    await tester.pumpWidget(host(cubit(), opened: opened));
    await tester.pumpAndSettle();
    expect(find.byType(PicoWovenBar), findsNWidgets(13));
    // Value sort: the largest first.
    final first = tester.getTopLeft(find.text('Kota Palu')).dy;
    final last = tester.getTopLeft(find.text('Banggai Kepulauan')).dy;
    expect(first, lessThan(last));
    expect(
      find.bySemanticsLabel('Kota Palu, positif kumulatif 2.200, 14 Jan 2024'),
      findsOneWidget,
    );
    await tester.tap(find.text('Nama'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Banggai').first).dy,
      lessThan(tester.getTopLeft(find.text('Tolitoli')).dy),
    );
    await tester.tap(find.text('Kota Palu'));
    expect(opened.last, '/statistik/kabupaten/7271');
    h.dispose();
  });

  testWidgets(
    'one regency failing: 12 rows and a retry row for the failed one',
    (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(cubit(summaries: all13(except: '7204'))));
      await tester.pumpAndSettle();
      expect(find.byType(PicoWovenBar), findsNWidgets(12));
      expect(find.text('Data Poso belum bisa dimuat'), findsOneWidget);
      expect(find.text('Coba muat lagi'), findsOneWidget);
    },
  );

  testWidgets('progress text while the first load arrives, none when done', (
    tester,
  ) async {
    await page.setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = cubit(summaries: all13().take(5).toList());
    await tester.pumpWidget(host(c));
    await tester.pump();
    // The stream already ended in the fake; check the live progress state.
    expect(c.state.summaries!.data.length, 5);
    await tester.pumpAndSettle();
    // Ended with 8 missing: they are failed rows, not endless "loading".
    expect(find.textContaining('Memuat 5 dari 13'), findsNothing);
    expect(find.text('Coba muat lagi'), findsNWidgets(8));
  });

  testWidgets('offline with no data is the offline state; english; scale 2', (
    tester,
  ) async {
    await page.setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(cubit(offline: true)));
    await tester.pumpAndSettle();
    expect(find.byType(PicoStateView), findsOneWidget);
    await page.setup(tester, AppLocale.en);
    await tester.pumpWidget(
      host(cubit(), scale: 2, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Regencies and cities'), findsOneWidget);
    expect(find.text('See on the map'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await page.setup(tester, AppLocale.id);
  });

  group('regency area page', () {
    testWidgets('a regency shows the area page with no ODP/PDP and no gender', (
      tester,
    ) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = sultengSeries(area: const AreaRef.regency('7271'));
      await tester.pumpWidget(
        page.host(
          CountingCases(s),
          const AreaQuery(area: AreaRef.regency('7271')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sulawesi Tengah'), findsWidgets);
      expect(find.text('ODP dan PDP'), findsNothing);
      expect(find.text('Jenis kelamin dan usia'), findsNothing);
      expect(find.text('Ganti provinsi'), findsNothing);
    });

    testWidgets('an unknown code is the not-found state', (tester) async {
      await page.setup(tester, AppLocale.id);
      await tester.pumpWidget(
        page.host(
          CountingCases(sultengSeries()),
          const AreaQuery(area: AreaRef.regency('9999')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wilayah tidak ditemukan.'), findsOneWidget);
    });
  });

  for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
    final n = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
    testWidgets('golden kabupaten $n', (tester) async {
      await page.setup(tester, AppLocale.id);
      tester.view.physicalSize = Size(412, scale == 2 ? 9000 : 3400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          cubit(summaries: all13(except: '7204')),
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
        matchesGoldenFile('goldens/kabupaten_$n.png'),
      );
    }, tags: ['golden']);
  }
}
