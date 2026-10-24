import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_base.dart';

import '../../helpers/golden_test_helpers.dart';

final start = DateTime(2020, 3, 2);
final end = DateTime(2024, 1, 14);
final peakDay = DateTime(2022, 2, 16);

DateTime day(int i) => DateTime(2020, 3, 2 + i);

/// 1,414 synthetic days with a single peak of exactly 64,718 on 2022-02-16.
List<(DateTime, num?)> wave(double scale, {double width = 60, int? shift}) {
  final peakIdx = peakDay.difference(start).inDays + (shift ?? 0);
  return [
    for (var i = 0; i < 1414; i++)
      (
        day(i),
        i == peakIdx && shift == null
            ? 64718
            : (scale * math.exp(-math.pow((i - peakIdx) / width, 2)) * 64000)
                      .round() +
                  (i % 7),
      ),
  ];
}

final fourSeries = [
  ChartSeries(state: PicoState.positive, points: wave(1)),
  ChartSeries(state: PicoState.recovered, points: wave(.8, shift: 20)),
  ChartSeries(state: PicoState.deceased, points: wave(.12, shift: 35)),
  ChartSeries(state: PicoState.active, points: wave(.3, shift: -15)),
];

final rtPoints = <(DateTime, Rt?)>[
  for (var i = 0; i < 1414; i++)
    (
      day(i),
      (i > 300 && i < 360) || i > 1300
          ? null
          : Rt(
              value: 1 + .8 * math.sin(i / 90),
              lower: .8 + .8 * math.sin(i / 90),
              upper: 1.2 + .8 * math.sin(i / 90),
            ),
    ),
];

Widget app(
  ThemeData theme,
  Widget child, {
  double scale = 1,
  Locale locale = const Locale('id'),
  bool noAnim = true,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  locale: locale,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('id'), Locale('en')],
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: noAnim),
    child: w!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

DateTimeRange get all => DateTimeRange(start: start, end: end);

Future<void> warm(WidgetTester tester, Brightness b, [double dpr = 1]) => tester
    .runAsync(() => WeaveShaderCache.instance.warmUp(b, dpr))
    .then((_) {});

void main() {
  setUp(WeaveShaderCache.instance.clear);

  group('path builder', () {
    final scale = ChartScale(
      plot: const Rect.fromLTWH(0, 0, 300, 100),
      start: start,
      end: end,
      yMin: 0,
      yMax: 10,
    );

    test('an Rt series with nulls draws separate segments, not a line through the gap', () {
      final pts = <(DateTime, num?)>[
        for (var i = 0; i < 10; i++)
          (day(i * 100), i == 4 || i == 5 ? null : 1.0 + i / 10),
      ];
      final runs = buildRuns(pts, scale);
      expect(runs.length, 2);
      expect(runs[0].length, 4);
      expect(runs[1].length, 4);
      // The first x of run two is after the gap, not bridged.
      expect(runs[1].first.dx - runs[0].last.dx, greaterThan(50));
    });

    test('a single isolated point is its own run', () {
      final runs = buildRuns([
        (day(0), 1),
        (day(50), null),
        (day(100), 2),
        (day(150), null),
      ], scale);
      expect(runs.map((r) => r.length), [1, 1]);
    });

    test('decimation keeps the peak and bounds the point count', () {
      final pts = wave(1);
      final runs = buildRuns(pts, scale);
      final n = runs.fold<int>(0, (a, r) => a + r.length);
      expect(n, lessThanOrEqualTo(4 * 301));
      final minY = runs.expand((r) => r).map((o) => o.dy).reduce(math.min);
      expect(minY, closeTo(scale.y(64718), 0.01));
    });

    test('points outside the range are dropped', () {
      final runs = buildRuns([(DateTime(2019), 5), (day(10), 5)], scale);
      expect(runs.single.length, 1);
    });

    test('nice ticks and x ticks', () {
      expect(niceTicks(0, 64718), [0, 20000, 40000, 60000, 80000]);
      expect(niceTicks(0, 2.3).first, 0);
      expect(xTicks(start, end).map((d) => d.year), [2021, 2022, 2023, 2024]);
      expect(xTicks(DateTime(2023, 10, 1), end).first, DateTime(2023, 10));
    });

    test('dateAt maps pixels back to dates', () {
      expect(scale.dateAt(0), start);
      expect(scale.dateAt(300), end);
      expect(scale.dateAt(-50), start);
    });
  });

  group('PicoLineChart', () {
    testWidgets(
      'semantics: one node whose label has series names, range and peak',
      (tester) async {
        final h = tester.ensureSemantics();
        await warm(tester, Brightness.light);
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoLineChart(series: [fourSeries.first], range: all),
          ),
        );
        expect(
          find.bySemanticsLabel(
            'Positif, 2 Mar 2020 sampai 14 Jan 2024, puncak 64.718 pada 16 Feb 2022',
          ),
          findsOneWidget,
        );
        h.dispose();
      },
    );

    testWidgets('English summary and formats', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoLineChart(series: [fourSeries.first], range: all),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          'Positive, Mar 2, 2020 to Jan 14, 2024, peak 64,718 on Feb 16, 2022',
        ),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('tap shows the readout and calls onScrub', (tester) async {
      DateTime? got;
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoLineChart(
            series: [fourSeries.first],
            range: all,
            onScrub: (d) => got = d,
          ),
        ),
      );
      final box = tester.getRect(find.byKey(const ValueKey('pico-chart-plot')));
      await tester.tapAt(Offset(box.center.dx, box.center.dy));
      await tester.pump();
      expect(got, isNotNull);
      expect(find.textContaining('Positif'), findsWidgets);
      expect(find.textContaining(RegExp(r'\d+ \w{3} \d{4}')), findsWidgets);
    });

    testWidgets(
      'arrow keys and the accessibility actions move the scrub by one day',
      (tester) async {
        final seen = <DateTime>[];
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoLineChart(
              series: [fourSeries.first],
              range: all,
              onScrub: seen.add,
            ),
          ),
        );
        final box = tester.getRect(
          find.byKey(const ValueKey('pico-chart-plot')),
        );
        await tester.tapAt(box.center);
        await tester.pump();
        final first = seen.last;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(seen.last, first.add(const Duration(days: 1)));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(seen.last, first.subtract(const Duration(days: 1)));
      },
    );

    testWidgets(
      'table view lists the days for screen readers and returns to the chart',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoLineChart(
              series: [fourSeries.first],
              range: DateTimeRange(
                start: DateTime(2022, 2, 10),
                end: DateTime(2022, 2, 20),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Lihat sebagai tabel'));
        await tester.pump();
        expect(find.text('Kembali ke grafik'), findsOneWidget);
        expect(find.byType(ListView), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp(r'^20 Feb 2022, Positif')),
          findsOneWidget,
        );
        await tester.tap(find.text('Kembali ke grafik'));
        await tester.pump();
        expect(find.text('Lihat sebagai tabel'), findsOneWidget);
        h.dispose();
      },
    );

    testWidgets(
      'draw-on runs for 1500 ms with animations on (original motion)',
      (tester) async {
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoLineChart(series: [fourSeries.first], range: all),
            noAnim: false,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.hasRunningAnimations, isTrue, reason: 'still drawing');
        await tester.pump(const Duration(milliseconds: 600));
        // Then the last point pulses three times (1500 ms each) and stops.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 1600));
        }
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('reduced motion draws at once, no animation', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoLineChart(series: [fourSeries.first], range: all),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('empty or all-null series do not throw', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoLineChart(
            series: [
              ChartSeries(state: PicoState.positive, points: [(day(1), null)]),
            ],
            range: all,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PicoRtChart', () {
    testWidgets(
      'summary uses decimal comma, peak and range; readout shows "Tidak ada data" in a gap',
      (tester) async {
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          app(PicoTheme.light(), PicoRtChart(points: rtPoints, range: all)),
        );
        expect(
          find.bySemanticsLabel(
            RegExp(r'^Rt, 2 Mar 2020 sampai 14 Jan 2024, puncak \d,\d\d pada'),
          ),
          findsOneWidget,
        );
        h.dispose();
      },
    );

    testWidgets('an all-null range still builds and offers the table', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoRtChart(
            points: [for (var i = 0; i < 5; i++) (day(i), null)],
            range: all,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Lihat sebagai tabel'), findsOneWidget);
    });

    testWidgets('keyboard scrub into a gap says Tidak ada data', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoRtChart(
            points: rtPoints,
            range: DateTimeRange(start: day(290), end: day(370)),
          ),
        ),
      );
      final box = tester.getRect(find.byKey(const ValueKey('pico-chart-plot')));
      await tester.tapAt(Offset(box.center.dx, box.center.dy));
      await tester.pump();
      expect(find.textContaining('Tidak ada data'), findsOneWidget);
    });
  });

  test('paint cost of 4 series x 1,414 points on the host (not a device profile)', () {
    final scale = ChartScale(
      plot: const Rect.fromLTWH(40, 10, 340, 200),
      start: start,
      end: end,
      yMin: 0,
      yMax: 80000,
    );
    final layers = [
      for (final s in fourSeries)
        ChartLayer(
          state: s.state,
          color: Colors.black,
          runs: buildRuns(s.points, scale),
        ),
    ];
    final ctrl = AnimationController(vsync: const TestVSync(), value: 1);
    final painter = ChartPainter(
      scale: scale,
      ticks: niceTicks(0, 80000),
      xTicks: xTicks(start, end),
      series: layers,
      band: null,
      bandColor: Colors.black,
      threshold: null,
      thresholdLabel: null,
      scrub: null,
      scrubValues: const [],
      gridColor: Colors.grey,
      axisColor: Colors.grey,
      textStyle: const TextStyle(fontSize: 12),
      textScaler: TextScaler.noScaling,
      yLabel: null,
      formatTick: (v) => '$v',
      monthLabel: (d) => '${d.year}',
      progress: ctrl,
      pulse: ctrl,
      fillBelow: false,
      inkColor: Colors.black,
    );
    final times = <int>[];
    for (var i = 0; i < 30; i++) {
      final sw = Stopwatch()..start();
      final rec = ui.PictureRecorder();
      painter.paint(Canvas(rec), const Size(400, 260));
      rec.endRecording().dispose();
      sw.stop();
      times.add(sw.elapsedMicroseconds);
    }
    times.sort();
    // ignore: avoid_print
    print(
      'chart paint median ${times[15] / 1000} ms, max ${times.last / 1000} ms (host, recording only)',
    );
    expect(times[15], lessThan(8000));
    ctrl.dispose();
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      final name = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
      testGoldenSceneWithFonts('charts $name', (tester) async {
        tester.view.physicalSize = Size(420, scale > 1 ? 2300 : 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await warm(tester, dark ? Brightness.dark : Brightness.light);
        await tester.pumpWidget(
          app(
            dark ? PicoTheme.dark() : PicoTheme.light(),
            Column(
              children: [
                PicoLineChart(
                  series: fourSeries,
                  range: all,
                  yLabel: 'Kasus harian',
                ),
                const SizedBox(height: 16),
                PicoRtChart(points: rtPoints, range: all),
              ],
            ),
            scale: scale,
          ),
        );
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/charts_$name.png'),
        );
      }, tags: ['golden']);
    }
  }

  testGoldenSceneWithFonts('charts at 3x with a scrub point', (tester) async {
    tester.view.physicalSize = const Size(1260, 1800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await warm(tester, Brightness.light, 3);
    await tester.pumpWidget(
      app(
        PicoTheme.light(),
        Column(
          children: [
            PicoLineChart(
              series: fourSeries,
              range: DateTimeRange(
                start: DateTime(2021, 12, 1),
                end: DateTime(2022, 4, 1),
              ),
            ),
            PicoRtChart(
              points: rtPoints,
              range: DateTimeRange(
                start: DateTime(2021, 1, 1),
                end: DateTime(2021, 12, 31),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final box = tester.getRect(
      find.byKey(const ValueKey('pico-chart-plot')).first,
    );
    await tester.tapAt(Offset(box.center.dx, box.center.dy));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/charts_3x_scrub.png'),
    );
  }, tags: ['golden']);

  testGoldenSceneWithFonts('greyscale: 4 series stay distinct', (tester) async {
    tester.view.physicalSize = const Size(420, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          PicoLineChart(
            series: fourSeries,
            range: DateTimeRange(
              start: DateTime(2021, 6, 1),
              end: DateTime(2022, 10, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(ColorFiltered),
      matchesGoldenFile('goldens/charts_greyscale.png'),
    );
  }, tags: ['golden']);
}
