import 'dart:io';

import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peta/src/domain/map_values.dart';
import 'package:peta/src/domain/regions.dart';
import 'package:peta/src/l10n/translations.g.dart';
import 'package:peta/src/presentation/bloc/peta_bloc.dart';
import 'package:peta/src/presentation/bloc/peta_event.dart';
import 'package:peta/src/presentation/ui/pages/peta_page.dart';
import 'package:peta/src/presentation/ui/widgets/peta_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

const names = {
  '7201': 'Banggai Kepulauan',
  '7202': 'Banggai',
  '7203': 'Morowali',
  '7204': 'Poso',
  '7205': 'Donggala',
  '7206': 'Toli-Toli',
  '7207': 'Buol',
  '7208': 'Parigi Moutong',
  '7209': 'Tojo Una-Una',
  '7210': 'Sigi',
  '7211': 'Banggai Laut',
  '7212': 'Morowali Utara',
  '7271': 'Kota Palu',
};

CaseDay day(DateTime d, int positive, {Rt? rt}) => CaseDay(
  date: d,
  daily: CaseCounts.zero,
  cumulative: CaseCounts(
    positive: positive,
    recovered: positive ~/ 2,
    deceased: 3,
    active: 5,
  ),
  rt: rt,
);

/// Kota Palu is the largest (13.824), the rest grow by code.
List<AreaSummary> summaries({bool withRt = false}) => [
  for (final (i, e) in names.entries.indexed)
    AreaSummary(
      area: AreaRef.regency(e.key),
      name: e.value,
      latest: day(
        DateTime(2024, 1, 14),
        e.key == '7271' ? 13824 : 1000 + i * 100,
        rt: withRt && i.isEven
            ? Rt(value: 0.9 + i / 100, lower: .8, upper: 1.1)
            : null,
      ),
    ),
];

/// Series of every regency whose day index is wrong on purpose: only the date
/// is right (keyed by date, never by `day`).
class PastCases extends FakeCaseRepository {
  PastCases({super.regencies});

  final seriesCalls = <String>[];

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) {
    final code = (area as RegencyArea).code;
    seriesCalls.add(code);
    final base = int.parse(code.substring(2));
    return Stream.value(
      fakeSnapshot(
        CaseSeries.fromDays(
          area: area,
          areaName: names[code]!,
          days: [
            day(DateTime(2021, 7, 14), base),
            day(DateTime(2021, 7, 15), base * 10),
            day(DateTime(2024, 1, 14), 99999),
          ],
        ),
      ),
    );
  }
}

Future<List<Region>> regions() async =>
    parseRegions(File('assets/geojson/sulteng.json').readAsStringSync());

Widget host(
  FakeCaseRepository repo, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
  List<String>? opened,
  String? metric,
  String? date,
  Future<DateTime?> Function(BuildContext)? pickDate,
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
      body: BlocProvider(
        key: UniqueKey(),
        create: (_) =>
            PetaBloc(repo, regions: regions)..add(const PetaStarted()),
        child: PetaContent(
          initialMetric: metric,
          initialDate: date,
          onOpen: (p) => opened?.add(p),
          pickDate: pickDate,
        ),
      ),
    ),
  ),
);

FakeCaseRepository repo({bool withRt = false}) =>
    FakeCaseRepository(regencies: fakeSnapshot(summaries(withRt: withRt)));

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 3000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first paint: the bundled file parses in under 100 ms and the '
      'map builds and paints in under 300 ms (host proxy, not a device '
      'measurement)', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    // Best of three: a loaded CI machine must not fail a budget test, a slow
    // algorithm still does.
    var bestParse = 1 << 30;
    late List<Region> rs;
    for (var i = 0; i < 3; i++) {
      final parse = Stopwatch()..start();
      rs = await regions();
      parse.stop();
      if (parse.elapsedMilliseconds < bestParse) {
        bestParse = parse.elapsedMilliseconds;
      }
    }
    expect(bestParse, lessThan(100));
    // Warm the bloc: the page is built with outlines and values at hand.
    await tester.pumpWidget(host(repo()));
    await settle(tester);
    var best = 1 << 30;
    for (var i = 0; i < 3; i++) {
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: PicoTheme.light(),
          home: Scaffold(
            body: PetaMap(
              regions: rs,
              values: const [],
              metric: PetaMetric.positive,
              selected: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      sw.stop();
      if (sw.elapsedMilliseconds < best) best = sw.elapsedMilliseconds;
    }
    expect(best, lessThan(300));
  });

  testWidgets('13 marks, semantics in list order: name, value and date', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(repo()));
    await settle(tester);
    expect(
      find.bySemanticsLabel('Kota Palu, positif 13.824, 14 Jan 2024'),
      findsOneWidget,
    );
    final labels = <String>[];
    void walk(SemanticsNode n) {
      if (n.label.contains(', positif ') && n.label.endsWith('2024')) {
        labels.add(n.label);
      }
      for (final c in n.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        walk(c);
      }
    }

    walk(tester.getSemantics(find.byType(PetaMap)));
    expect(labels, hasLength(13));
    expect(labels.first, startsWith('Kota Palu'));
    // Same order as the list: value high to low.
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.text('13.824'), findsOneWidget);
    h.dispose();
  });

  testWidgets('a mark is at least 44 dp and Kota Palu opens its sheet; '
      '"Lihat statistik" goes to the kabupaten page', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final opened = <String>[];
    await tester.pumpWidget(host(repo(), opened: opened));
    await settle(tester);
    final palu = find.bySemanticsLabel(RegExp('^Kota Palu, positif'));
    final size = tester.getSize(palu);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    await tester.tap(palu);
    await settle(tester);
    expect(find.text('Positif: 13.824'), findsOneWidget);
    expect(find.text('Tanggal data: 14 Jan 2024'), findsOneWidget);
    await tester.tap(find.byType(PicoButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(opened.last, '/statistik/kabupaten/7271');
  });

  testWidgets('a tap on an outline selects that kabupaten', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(host(repo()));
    await settle(tester);
    final map = find.byType(PetaMap);
    final rs = await regions();
    final pr = MapProjection(rs);
    final size = tester.getSize(map);
    final poso = rs.firstWhere((r) => r.code == '7204');
    // A point inside Poso that is far from any mark: shift from its label point.
    final at = pr.project(poso.labelPoint[0], poso.labelPoint[1], size);
    await tester.tapAt(tester.getTopLeft(map) + at + const Offset(0, 0));
    await settle(tester);
    expect(find.textContaining('Tanggal data: 14 Jan 2024'), findsOneWidget);
  });

  testWidgets(
    'Rt: a null Rt is a hollow ring and "Rt tidak dihitung", never 0',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      await tester.pumpWidget(host(repo(withRt: true), metric: 'rt'));
      await settle(tester);
      expect(find.text('Rt tidak dihitung'), findsWidgets);
      await tester.tap(find.text('Daftar'));
      await settle(tester);
      expect(find.text('Rt tidak dihitung'), findsNWidgets(6));
      expect(find.textContaining('0,00'), findsNothing);
    },
  );

  testWidgets('a chosen date loads the 13 series and reads the day by date, '
      'not by index', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final r = PastCases(regencies: fakeSnapshot(summaries()));
    await tester.pumpWidget(
      host(r, pickDate: (_) async => DateTime(2021, 7, 15)),
    );
    await settle(tester);
    await tester.tap(find.text('Pilih tanggal'));
    await settle(tester);
    expect(r.seriesCalls.toSet(), hasLength(13));
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    // Kota Palu on 2021-07-15: base 71 * 10.
    expect(find.text('710'), findsOneWidget);
    expect(find.text('15 Jul 2021'), findsNWidgets(14)); // 13 rows + the button
    expect(find.text('99.999'), findsNothing);
  });

  testWidgets('URL parameters: metric and a plain YYYY-MM-DD date', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final r = PastCases(regencies: fakeSnapshot(summaries()));
    await tester.pumpWidget(host(r, metric: 'recovered', date: '2021-07-14'));
    await settle(tester);
    await tester.tap(find.text('Daftar'));
    await settle(tester);
    expect(find.text('14 Jul 2021'), findsNWidgets(14)); // 13 rows + the button
    expect(find.text('Sembuh'), findsWidgets);
    // A bad date is ignored.
    await tester.pumpWidget(host(repo(), date: '2021-02-31'));
    await settle(tester);
    expect(find.text('Terbaru'), findsOneWidget);
  });

  testWidgets('legend shows the six mark sizes with their ranges', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(host(repo()));
    await settle(tester);
    expect(find.text('Ukuran tanda'), findsOneWidget);
    expect(find.textContaining(' sampai '), findsWidgets);
    expect(find.textContaining('6 kelompok'), findsOneWidget);
  });

  testWidgets('offline with nothing saved is the offline state; english; '
      'scale 2.0', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 9000);
    await tester.pumpWidget(host(FakeCaseRepository(regencies: fakeFailure())));
    await settle(tester);
    expect(find.byType(PicoStateView), findsOneWidget);
    await setup(tester, AppLocale.en);
    await tester.pumpWidget(host(repo(), scale: 2, locale: const Locale('en')));
    await settle(tester);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Mark size'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await setup(tester, AppLocale.id);
  });

  testWidgets('golden map light x1 and dark x2 with one selected kabupaten', (
    tester,
  ) async {
    for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
      await setup(tester, AppLocale.id);
      big(tester, scale == 2 ? 3600 : 1900);
      await tester.pumpWidget(
        host(
          repo(),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: scale,
        ),
      );
      await settle(tester);
      final ctx = tester.element(find.byType(PetaContent));
      ctx.read<PetaBloc>().add(const PetaSelected('7271'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/peta_${dark ? 'dark' : 'light'}_x${scale.toInt()}.png',
        ),
      );
    }
  }, tags: ['golden']);
}
