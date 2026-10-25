import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/ui/pages/tests_page.dart';
import 'package:statistik/src/presentation/ui/widgets/tests_widgets.dart';

const _types = [
  TestType(
    key: 'pcr',
    name: 'Polymerase Chain Reaction',
    sample: 'Spesimen saluran pernapasan',
    duration: 'Tergantung banyak antrian sampel',
    isRecommended: true,
  ),
  TestType(
    key: 'rdt',
    name: 'Rapid Diagnostic Test',
    sample: 'Tergantung tes',
    duration: 'Tergantung tes',
    isRecommended: false,
  ),
  TestType(
    key: 'tcm',
    name: 'Tes Cepat Molekuler',
    sample: 'Swab pangkal hidung dan tenggorokan',
    duration: 'minimal 45 - 60 Menit',
    isRecommended: false,
  ),
  TestType(
    key: 'rdt_ab',
    name: 'Rapid Diagnostic Test - Antibodi',
    sample: 'Darah',
    duration: 'minimal 10 - 15 Menit',
    isRecommended: false,
  ),
  TestType(
    key: 'rdt_ag',
    name: 'Rapid Diagnostic Test - Antigen',
    sample: 'Swab',
    duration: 'maksimal 60 - 90 Menit',
    isRecommended: false,
  ),
];

const _totals = [
  TestTotal(
    typeKey: 'pcr',
    sourceDay: 520,
    process: 174,
    invalid: 0,
    positive: 193,
    negative: 1406,
  ),
  TestTotal(
    typeKey: 'rdt',
    sourceDay: 520,
    process: 3316,
    invalid: 0,
    positive: 187,
    negative: 3247,
  ),
];

Widget host(
  FakeStatsRepository stats, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
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
          BlocProvider(create: (_) => TestTypesCubit(stats.watchTestTypes)),
          BlocProvider(create: (_) => TestTotalsCubit(stats.watchLatestTests)),
        ],
        child: const TestsPage(),
      ),
    ),
  ),
);

FakeStatsRepository stats() => FakeStatsRepository()
  ..testTypes = fakeSnapshot(_types)
  ..latestTests = fakeSnapshot(_totals);

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 4500]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('badges and icons per key', () {
    expect(
      [for (final t in _types) testBadge(t.key)],
      ['PCR', 'RDT', 'TCM', 'RDT-Ab', 'RDT-Ag'],
    );
    expect(testIconKey('pcr'), 'test.pcr');
    expect(testIconKey('rdt_ag'), 'test.rapid');
    expect(PicoIconRegistry.has(testIconKey('pcr')), isTrue);
    expect(PicoIconRegistry.has(testIconKey('rdt')), isTrue);
  });

  testWidgets('5 type cards; PCR is recommended in text; no dates; types '
      'without rows say so', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(host(stats()));
    await tester.pumpAndSettle();
    expect(find.byType(TestCard), findsNWidgets(5));
    expect(find.text('Direkomendasikan'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.textContaining('PCR · Polymerase'),
          matching: find.byType(TestCard),
        ),
        matching: find.text('Direkomendasikan'),
      ),
      findsOneWidget,
    );
    expect(find.byType(PicoWovenBar), findsNWidgets(2));
    expect(find.text('Belum ada data jumlah tes'), findsNWidgets(3));
    expect(
      find.textContaining('Data terakhir yang tercatat (awal pandemi)'),
      findsOneWidget,
    );
    // The totals carry no date at all: no year, no month name, no "day".
    expect(find.textContaining('2020'), findsNothing);
    expect(find.textContaining('520'), findsNothing);
    expect(find.text('1.406'), findsOneWidget);
  });

  testWidgets('API text keeps the id locale in the English UI', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester);
    await tester.pumpWidget(host(stats(), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('COVID-19 tests'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    final api = tester.widget<Text>(find.textContaining('PCR · Polymerase'));
    expect(api.locale, const Locale('id'));
    final sample = tester.widget<Text>(find.textContaining('Sample: Spesimen'));
    expect(sample.locale, const Locale('id'));
    await setup(tester, AppLocale.id);
  });

  testWidgets('offline with nothing saved is the offline state', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(FakeStatsRepository()..testTypes = fakeFailure()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PicoStateView), findsOneWidget);
  });

  testWidgets('guidelines and text scale 2.0', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 9000);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(stats(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
    h.dispose();
  });

  testWidgets('golden tes light x1 and dark x2', (tester) async {
    for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
      await setup(tester, AppLocale.id);
      big(tester, scale == 2 ? 9000 : 3000);
      await tester.pumpWidget(
        host(
          stats(),
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
          'goldens/tes_${dark ? 'dark' : 'light'}_x${scale.toInt()}.png',
        ),
      );
    }
  }, tags: ['golden']);
}
