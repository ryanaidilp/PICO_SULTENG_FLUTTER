import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/rt_view.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/regencies_cubit.dart';
import 'package:statistik/src/presentation/bloc/rt_bloc.dart';
import 'package:statistik/src/presentation/ui/pages/rt_page.dart';

CaseDay day(DateTime d, {Rt? rt}) => CaseDay(
  date: d,
  daily: CaseCounts.zero,
  cumulative: CaseCounts.zero,
  rt: rt,
);

/// National days: Rt on 2023-07-01..09 (0.46 on 07-02), null before and after.
CaseSeries nationalRt() => CaseSeries.fromDays(
  area: const AreaRef.national(),
  areaName: 'Indonesia',
  days: [
    for (var i = 20; i <= 30; i++) day(DateTime(2023, 6, i)),
    for (var i = 1; i <= 9; i++)
      day(
        DateTime(2023, 7, i),
        rt: i == 2
            ? const Rt(value: 0.46, lower: 0.41, upper: 0.513)
            : Rt(value: i.isEven ? 0.9 : 1.2, lower: 0.8, upper: 1.4),
      ),
  ],
);

class RtCases extends FakeCaseRepository {
  RtCases(CaseSeries s) : super(series: {s.area: s});

  final calls = <AreaRef>[];

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) {
    calls.add(area);
    return super.watchSeries(area, forceRefresh: forceRefresh);
  }
}

Widget host(
  RtCases repo,
  AreaRef initial, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
  List<String>? navigated,
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
      body: MultiBlocProvider(
        key: UniqueKey(),
        providers: [
          BlocProvider(create: (_) => RtBloc(repo)),
          BlocProvider(
            create: (_) => RegenciesCubit(
              repo,
              FakeDirectoryRepository()
                ..regencies = fakeSnapshot(const [
                  Regency(code: '7271', name: 'Kota Palu'),
                ]),
            ),
          ),
        ],
        child: RtContent(
          initial: initial,
          onNavigate: (p) => navigated?.add(p),
          onOpen: (p) => opened?.add(p),
        ),
      ),
    ),
  ),
);

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 4000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('rt view', () {
    test('area param parsing never throws', () {
      expect(parseRtArea(null), const AreaRef.national());
      expect(parseRtArea('province:72'), const AreaRef.province('72'));
      expect(parseRtArea('regency:7271'), const AreaRef.regency('7271'));
      expect(parseRtArea('province:7'), const AreaRef.national());
      expect(parseRtArea('x:1'), const AreaRef.national());
      expect(rtAreaParam(const AreaRef.regency('7271')), 'regency:7271');
    });

    test('latest computed, null days and the share above 1', () {
      final v = buildRtView(nationalRt())!;
      expect(v.latest!.date, DateTime(2023, 7, 9));
      expect(v.nullDays, 11);
      expect(v.computedDays, 9);
      expect(v.daysAboveOne, 5); // odd days 1,3,5,7,9 are 1.2
      final one = buildRtView(
        nationalRt(),
        from: DateTime(2023, 7, 2),
        to: DateTime(2023, 7, 2),
      )!;
      expect(one.latest!.rt.value, 0.46);
      expect(one.nullDays, 0);
    });

    test('a range before or after the data is clamped, never empty', () {
      final v = buildRtView(
        nationalRt(),
        from: DateTime(2000),
        to: DateTime(2100),
      )!;
      expect(v.points.length, 20);
    });
  });

  testWidgets('fixture 2023-07-02 reads 0,46 (0,41 sampai 0,51) in id', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final repo = RtCases(nationalRt());
    await tester.pumpWidget(host(repo, const AreaRef.national()));
    await tester.pumpAndSettle();
    // Open range: latest is 9 Jul. Narrow to 2 Jul with the bloc.
    final ctx = tester.element(find.byType(RtContent));
    ctx.read<RtBloc>().add(
      RtRangeChanged(
        DateTimeRange(start: DateTime(2023, 7, 2), end: DateTime(2023, 7, 2)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Rt 0,46 (0,41 sampai 0,51) pada 2 Jul 2023'),
      findsOneWidget,
    );
    expect(repo.calls, [const AreaRef.national()], reason: 'no new request');
  });

  testWidgets('english: 0.46 (0.41 to 0.51), method numbers from RtMethod', (
    tester,
  ) async {
    await setup(tester, AppLocale.en);
    big(tester, 6000);
    await tester.pumpWidget(
      host(
        RtCases(nationalRt()),
        const AreaRef.national(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(RtContent));
    ctx.read<RtBloc>().add(
      RtRangeChanged(
        DateTimeRange(start: DateTime(2023, 7, 2), end: DateTime(2023, 7, 2)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rt 0.46 (0.41 to 0.51) on Jul 2, 2023'), findsOneWidget);
    expect(
      find.textContaining('mean 7.5 days and SD 3.4 days'),
      findsOneWidget,
    );
    expect(find.textContaining('7-day sliding window'), findsOneWidget);
    expect(find.textContaining('fewer than 12 cases'), findsOneWidget);
    await setup(tester, AppLocale.id);
  });

  testWidgets('a range with only null Rt shows the explainer and the reason, '
      'not an empty chart', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    await tester.pumpWidget(
      host(RtCases(nationalRt()), const AreaRef.national()),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(RtContent));
    ctx.read<RtBloc>().add(
      RtRangeChanged(
        DateTimeRange(start: DateTime(2023, 6, 20), end: DateTime(2023, 6, 25)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rt belum dihitung untuk rentang ini.'), findsOneWidget);
    expect(find.byType(PicoRtChart), findsNothing);
    expect(
      find.text('Rt tidak dihitung untuk 6 hari dalam rentang ini.'),
      findsOneWidget,
    );
    expect(find.textContaining('kurang dari 12 kasus'), findsWidgets);
    expect(find.text('Apa itu Rt'), findsOneWidget);
    expect(
      find.textContaining('rerata 7,5 hari dan SD 3,4 hari'),
      findsOneWidget,
    );
    expect(find.textContaining('jendela geser 7 hari'), findsOneWidget);
    expect(find.textContaining('9 Jul 2023'), findsWidgets);
  });

  testWidgets('chart summary says the share of days above 1; threshold has a '
      'text label', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      host(RtCases(nationalRt()), const AreaRef.national()),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(RtContent));
    ctx.read<RtBloc>().add(
      RtRangeChanged(
        DateTimeRange(start: DateTime(2023, 7, 1), end: DateTime(2023, 7, 9)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        RegExp('Rt di atas 1 pada 5 dari 9 hari yang dihitung \\(56%\\)'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Rt = 1: batas penularan bertambah dan berkurang'),
      findsOneWidget,
    );
    expect(find.textContaining('selang kredibel 95%'), findsWidgets);
    expect(find.textContaining('Hari data terakhir'), findsNothing);
    h.dispose();
  });

  testWidgets('latest Rt older than the newest data day says so', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    final s = CaseSeries.fromDays(
      area: const AreaRef.national(),
      areaName: 'Indonesia',
      days: [
        ...nationalRt().days,
        for (var i = 10; i <= 14; i++) day(DateTime(2023, 7, i)),
      ],
    );
    await tester.pumpWidget(host(RtCases(s), const AreaRef.national()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Hari data terakhir: 14 Jul 2023. Rt belum dihitung untuk hari itu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('area change updates the url, asks the repository once per area, '
      'and the method link opens Metodologi', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    final navigated = <String>[];
    final opened = <String>[];
    final repo = RtCases(nationalRt());
    repo.series[const AreaRef.province('72')] = CaseSeries.fromDays(
      area: const AreaRef.province('72'),
      areaName: 'Sulawesi Tengah',
      days: nationalRt().days,
    );
    await tester.pumpWidget(
      host(
        repo,
        const AreaRef.national(),
        navigated: navigated,
        opened: opened,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provinsi'));
    await tester.pumpAndSettle();
    expect(navigated.last, '/statistik/rt?area=province:72');
    expect(find.text('Sulawesi Tengah'), findsWidgets);
    expect(repo.calls, [
      const AreaRef.national(),
      const AreaRef.province('72'),
    ]);
    await tester.ensureVisible(find.text('Selengkapnya di Metodologi'));
    await tester.tap(find.text('Selengkapnya di Metodologi'));
    expect(opened.last, '/info/tentang#metodologi');
  });

  testWidgets('unknown area is not found; offline is the offline state', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(RtCases(nationalRt()), const AreaRef.province('99')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wilayah tidak ditemukan.'), findsOneWidget);
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 12000);
    await tester.pumpWidget(
      host(RtCases(nationalRt()), const AreaRef.national(), scale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden rt light x1 and dark x2', (tester) async {
    for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
      await setup(tester, AppLocale.id);
      big(tester, scale == 2 ? 9000 : 3600);
      await tester.pumpWidget(
        host(
          RtCases(nationalRt()),
          const AreaRef.national(),
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
        matchesGoldenFile(
          'goldens/rt_${dark ? 'dark' : 'light'}_x${scale.toInt()}.png',
        ),
      );
    }
  }, tags: ['golden']);
}
