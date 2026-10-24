import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

/// Theme sample page: type scale, buttons, segmented control, nav bar.
class _SamplePage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Display PICO', style: t.display.small),
          Text('Heading satu', style: t.heading.h1),
          Text('Heading dua', style: t.heading.h3),
          Text('Isi teks 64.718 kasus, 1.234.567 total', style: t.body.regular),
          Text('Keterangan kecil', style: t.body.small),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Utama')),
              OutlinedButton(onPressed: () {}, child: const Text('Garis')),
              TextButton(onPressed: () {}, child: const Text('Teks')),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Harian')),
              ButtonSegment(value: 1, label: Text('Kumulatif')),
            ],
            selected: const {0},
            onSelectionChanged: (_) {},
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(icon: Icon(Icons.apps), label: 'Layanan'),
          NavigationDestination(icon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }
}

Widget _app(ThemeData theme) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: const _SamplePage(),
);

void main() {
  final themes = {'light': PicoTheme.light(), 'dark': PicoTheme.dark()};

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    for (final scale in [1.0, 2.0]) {
      final tag = '${name}_x${scale.toStringAsFixed(0)}';
      testGoldenSceneWithFonts('theme sample $tag', (tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(420, 900),
              textScaler: TextScaler.linear(scale),
            ),
            child: _app(theme),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/theme_sample_$tag.png'),
        );
      }, tags: ['golden']);
    }

    testGoldenSceneWithFonts('text contrast and tap targets ($name)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(theme));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }

  test('theme uses bundled brand fonts and no Google Fonts', () {
    final style = PicoTheme.light().textTheme.headlineLarge!;
    expect(style.fontFamily, 'packages/pico_ui_kit/SourceSans3');
    final body = PicoTheme.light().textTheme.bodyMedium!;
    expect(body.fontFamily, 'packages/pico_ui_kit/SourceSans3');
    expect(body.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('theme extensions are registered for both themes', () {
    for (final t in themes.values) {
      expect(t.extension<PicoStateColors>(), isNotNull);
      expect(t.extension<PicoClothSurface>(), isNotNull);
      expect(t.cardTheme.elevation, 0);
      expect(t.appBarTheme.surfaceTintColor, Colors.transparent);
    }
  });
}
