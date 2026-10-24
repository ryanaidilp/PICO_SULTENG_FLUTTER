import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/area_bloc.dart';
import 'package:statistik/src/presentation/ui/pages/area_page.dart';
import 'package:statistik/src/presentation/ui/widgets/profile_widgets.dart';
import 'package:statistik/src/presentation/ui/widgets/province_picker.dart';
import 'package:pico_data_api/testing.dart';

import '../support.dart';

Widget host(
  CountingCases repo,
  AreaQuery initial, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
  List<String>? navigated,
  List<String>? opened,
  FakeStatsRepository? stats,
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
          BlocProvider(create: (_) => AreaBloc(repo)),
          BlocProvider(
            create: (_) => ProvincesCubit(repo.watchProvinceSummaries),
          ),
          BlocProvider(
            create: (_) => GenderCubit(
              (stats ??
                      (FakeStatsRepository()
                        ..latestGender = fakeSnapshot(genderSnapshot())))
                  .watchLatestGender,
            ),
          ),
        ],
        child: AreaContent(
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

class OfflineCases extends CountingCases {
  OfflineCases(super.s);

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) =>
      Stream.value(fakeFailure(PicoFailureKind.network));
}

void main() {
  final series = sultengSeries();

  testWidgets(
    'range 2021-07-15 to 2021-07-15: the positif tile shows +308 and the total is 308',
    (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final q = AreaQuery(
        area: const AreaRef.province('72'),
        from: DateTime(2021, 7, 15),
        to: DateTime(2021, 7, 15),
      );
      await tester.pumpWidget(host(CountingCases(series), q));
      await tester.pumpAndSettle();
      expect(find.text('▲ +308'), findsOneWidget);
      expect(find.text('Total dalam rentang: 308'), findsOneWidget);
      expect(find.text('Puncak harian: 308 pada 15 Jul 2021'), findsOneWidget);
      expect(find.text('Sulawesi Tengah'), findsWidgets);
    },
  );

  testWidgets('a negative daily active shows a minus sign and a down arrow', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final q = AreaQuery(
      area: const AreaRef.province('72'),
      metric: CaseMetric.active,
      from: DateTime(2021, 8, 1),
      to: DateTime(2021, 8, 1),
    );
    await tester.pumpWidget(host(CountingCases(series), q));
    await tester.pumpAndSettle();
    final neg = series.on(DateTime(2021, 8, 1))!.daily.active;
    expect(neg, isNegative);
    expect(find.textContaining('▼'), findsOneWidget);
    expect(find.textContaining('-'), findsWidgets);
  });

  testWidgets(
    'every control change updates the canonical URL and needs no new request',
    (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = CountingCases(series);
      final nav = <String>[];
      await tester.pumpWidget(host(repo, const AreaQuery(), navigated: nav));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sembuh').first);
      await tester.pumpAndSettle();
      expect(nav.last, '/statistik?metric=recovered');
      await tester.tap(find.text('Kumulatif'));
      await tester.pumpAndSettle();
      expect(nav.last, '/statistik?metric=recovered&daily=false');
      await tester.tap(find.text('30 hari'));
      await tester.pumpAndSettle();
      expect(
        nav.last,
        '/statistik?metric=recovered&from=2023-12-16&to=2024-01-14&daily=false',
      );
      expect(
        repo.calls[const AreaRef.national()],
        1,
        reason: 'three changes, one request',
      );
    },
  );

  testWidgets(
    'Provinsi level selects Sulawesi Tengah and Kabupaten opens the list',
    (tester) async {
      await setup(tester, AppLocale.id);
      final repo = CountingCases(series);
      final nav = <String>[];
      final open = <String>[];
      await tester.pumpWidget(
        host(repo, const AreaQuery(), navigated: nav, opened: open),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Provinsi'));
      await tester.pumpAndSettle();
      expect(nav.last, '/statistik?level=province&id=72');
      await tester.tap(find.text('Kabupaten'));
      expect(open.last, PicoRoutes.kabupatenList);
    },
  );

  testWidgets('Bandingkan overlays the four metrics only for cumulative data', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(CountingCases(series), const AreaQuery(daily: false)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<PicoLineChart>(find.byType(PicoLineChart)).series.length,
      1,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PicoLineChart>(find.byType(PicoLineChart)).series.length,
      4,
    );
  });

  testWidgets('a network failure with no copy is the offline state', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    await tester.pumpWidget(host(OfflineCases(series), const AreaQuery()));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byType(PicoStateView), findsOneWidget);
  });

  testWidgets('offline with no copy is the offline state; english labels', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    await tester.pumpWidget(
      host(
        CountingCases(series),
        const AreaQuery(area: AreaRef.province('99')),
      ),
    );
    await tester.pumpAndSettle();
    // An area the API does not know is "not found", not a retry.
    expect(find.text('Wilayah tidak ditemukan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
    await setup(tester, AppLocale.en);
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        CountingCases(series),
        const AreaQuery(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cumulative'), findsOneWidget);
    expect(find.textContaining('Daily peak:'), findsOneWidget);
    await setup(tester, AppLocale.id);
  });

  testWidgets('guidelines: tap targets, labels and contrast', (tester) async {
    await setup(tester, AppLocale.id);
    final h = tester.ensureSemantics();
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(CountingCases(series), const AreaQuery()));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('golden ${dark ? 'dark' : 'light'} at text scale 2.0', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 5200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          CountingCases(series),
          const AreaQuery(area: AreaRef.province('72'), daily: false),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/area_${dark ? 'dark' : 'light'}_x2.png'),
      );
    }, tags: ['golden']);
  }

  testWidgets('golden light at text scale 1.0', (tester) async {
    await setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 2300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        CountingCases(series),
        const AreaQuery(area: AreaRef.province('72')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/area_light_x1.png'),
    );
  }, tags: ['golden']);
}
