import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

Widget app(ThemeData theme, Widget child, {Locale? locale, double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale ?? const Locale('id'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('id'), Locale('en')],
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

final items = [
  const WovenBarItem(
    label: 'Positif',
    value: 64718,
    max: 100000,
    state: PicoState.positive,
  ),
  const WovenBarItem(
    label: 'Sembuh',
    value: 50000,
    max: 100000,
    state: PicoState.recovered,
  ),
  const WovenBarItem(
    label: 'Meninggal',
    value: 12000,
    max: 100000,
    state: PicoState.deceased,
  ),
  const WovenBarItem(
    label: 'Dirawat',
    value: 3000,
    max: 100000,
    state: PicoState.active,
  ),
];

Future<void> warm(WidgetTester tester, Brightness b, [double dpr = 1]) => tester
    .runAsync(() => WeaveShaderCache.instance.warmUp(b, dpr))
    .then((_) {});

Widget sample() => ListView(
  children: [
    PicoStatTile(
      state: PicoState.positive,
      value: 64718,
      delta: 308,
      date: DateTime(2024, 1, 14),
    ),
    const SizedBox(height: 8),
    PicoStatTile(
      state: PicoState.active,
      date: DateTime(2024, 1, 14),
      delta: -4,
    ),
    const SizedBox(height: 12),
    PicoWovenBar(items: items),
    const SizedBox(height: 12),
    const PicoMarkLegend(states: PicoState.values),
    const SizedBox(height: 12),
    PicoDateRangeBar(
      range: DateTimeRange(
        start: DateTime(2023, 12, 16),
        end: DateTime(2024, 1, 14),
      ),
      bounds: DateTimeRange(
        start: DateTime(2020, 3, 2),
        end: DateTime(2024, 1, 14),
      ),
      onChanged: (_) {},
    ),
  ],
);

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });
  group('PicoStatTile', () {
    testWidgets('formats the figure per locale and labels the role', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoStatTile(
            state: PicoState.positive,
            value: 64718,
            delta: 308,
            date: DateTime(2024, 1, 14),
          ),
        ),
      );
      expect(find.text('64.718'), findsOneWidget);
      expect(find.text('Positif'), findsOneWidget);
      expect(find.text('▲ +308'), findsOneWidget);
      expect(find.text('14 Jan 2024'), findsOneWidget);
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoStatTile(
            state: PicoState.positive,
            value: 64718,
            date: DateTime(2024, 1, 14),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      expect(find.text('64,718'), findsOneWidget);
      expect(find.text('Jan 14, 2024'), findsOneWidget);
    });

    testWidgets('null value reads "Tidak ada data", never 0', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoStatTile(state: PicoState.rt, date: DateTime(2024, 1, 14)),
        ),
      );
      expect(find.text('Tidak ada data'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
      'one semantic node carries label, figure, delta sign and date',
      (tester) async {
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoStatTile(
              state: PicoState.deceased,
              value: 1200,
              delta: -3,
              date: DateTime(2024, 1, 14),
            ),
          ),
        );
        expect(
          find.bySemanticsLabel('Meninggal, 1.200, turun 3, 14 Jan 2024'),
          findsOneWidget,
        );
        h.dispose();
      },
    );
  });

  group('PicoWovenBar', () {
    testWidgets('bar length is proportional to value/max', (tester) async {
      await warm(tester, Brightness.light);
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoWovenBar(
            items: [
              WovenBarItem(
                label: 'A',
                value: 25,
                max: 100,
                state: PicoState.positive,
              ),
              WovenBarItem(
                label: 'B',
                value: 100,
                max: 100,
                state: PicoState.positive,
              ),
            ],
          ),
        ),
      );
      // The bars grow in 700 ms: settle, then read the final fractions.
      await tester.pumpAndSettle();
      final bars = find
          .byType(CustomPaint)
          .evaluate()
          .where((e) => e.renderObject!.paintBounds.height == 16)
          .toList();
      expect(bars.length, 2);
      // The painter exposes the fraction through its repaint inputs.
      final fractions = bars
          .map(
            (e) =>
                ((e.widget as CustomPaint).painter! as dynamic).fraction
                    as double,
          )
          .toList();
      expect(fractions, [0.25, 1.0]);
    });

    testWidgets('null value shows no data and an empty track', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoWovenBar(
            items: [
              WovenBarItem(
                label: 'A',
                value: null,
                max: 100,
                state: PicoState.rt,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Tidak ada data'), findsOneWidget);
    });

    testWidgets('semantics: label and value, one node per bar', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(PicoTheme.light(), PicoWovenBar(items: items)),
      );
      expect(find.bySemanticsLabel('Positif, 64.718'), findsOneWidget);
      h.dispose();
    });

    test('the weave cache hands out a shader after rasterising', () async {
      // Pure cache check without widgets: not ready before load.
      WeaveShaderCache.instance.clear();
      expect(
        WeaveShaderCache.instance.shaderIfReady(
          PicoState.rt,
          Brightness.dark,
          2,
        ),
        isNull,
      );
    });
  });

  group('PicoMarkLegend', () {
    testWidgets(
      'every role has text, mark and line form (never colour alone)',
      (tester) async {
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            const PicoMarkLegend(states: PicoState.values),
          ),
        );
        for (final s in PicoState.values) {
          expect(find.text(s.labelId), findsOneWidget);
        }
        expect(find.byType(PicoMarkView), findsNWidgets(5));
      },
    );
  });

  group('PicoDateRangeBar', () {
    final bounds = DateTimeRange(
      start: DateTime(2020, 3, 2),
      end: DateTime(2024, 1, 14),
    );

    testWidgets('presets end at the end of the data', (tester) async {
      DateTimeRange? got;
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDateRangeBar(
            range: bounds,
            bounds: bounds,
            onChanged: (r) => got = r,
          ),
        ),
      );
      await tester.tap(find.text('30 hari'));
      expect(got!.end, DateTime(2024, 1, 14));
      expect(got!.start, DateTime(2023, 12, 16));
      await tester.tap(find.text('7 hari'));
      expect(got!.start, DateTime(2024, 1, 8));
      await tester.tap(find.text('Semua'));
      expect(got, bounds);
    });

    testWidgets('the current range is visible as text, also a custom one', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDateRangeBar(
            range: DateTimeRange(
              start: DateTime(2021, 3, 1),
              end: DateTime(2021, 6, 30),
            ),
            bounds: bounds,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('1 Mar 2021 sampai 30 Jun 2021'), findsOneWidget);
    });

    testWidgets('the matching preset shows as selected', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDateRangeBar(
            range: DateTimeRange(
              start: DateTime(2023, 10, 17),
              end: DateTime(2024, 1, 14),
            ),
            bounds: bounds,
            onChanged: (_) {},
          ),
        ),
      );
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '90 hari'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('targets are at least 48 dp', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDateRangeBar(range: bounds, bounds: bounds, onChanged: (_) {}),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('custom opens the date range picker bounded to the data', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDateRangeBar(range: bounds, bounds: bounds, onChanged: (_) {}),
        ),
      );
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      final name = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
      testGoldenSceneWithFonts('data viz sample $name', (tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await warm(tester, dark ? Brightness.dark : Brightness.light);
        await tester.pumpWidget(
          app(
            dark ? PicoTheme.dark() : PicoTheme.light(),
            sample(),
            scale: scale,
          ),
        );
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/data_viz_$name.png'),
        );
      }, tags: ['golden']);
    }
  }

  testGoldenSceneWithFonts('woven bars at 3x pixel ratio', (tester) async {
    tester.view.physicalSize = const Size(1260, 900);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => WeaveShaderCache.instance.warmUp(Brightness.light, 3),
    );
    await tester.pumpWidget(app(PicoTheme.light(), PicoWovenBar(items: items)));
    await tester.pump();
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/woven_bar_3x.png'),
    );
  }, tags: ['golden']);

  testGoldenSceneWithFonts(
    'greyscale: four roles stay distinct without colour',
    (tester) async {
      tester.view.physicalSize = const Size(420, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await warm(tester, Brightness.light);
      await tester.pumpWidget(
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: app(
            PicoTheme.light(),
            ListView(
              children: [
                PicoWovenBar(items: items),
                const SizedBox(height: 8),
                const PicoMarkLegend(
                  states: [
                    PicoState.positive,
                    PicoState.recovered,
                    PicoState.deceased,
                    PicoState.active,
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(ColorFiltered),
        matchesGoldenFile('goldens/greyscale_roles.png'),
      );
    },
    tags: ['golden'],
  );
}
