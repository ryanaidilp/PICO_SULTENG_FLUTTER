import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

const _newKeys = [
  'contact.phone',
  'contact.whatsapp',
  'contact.email',
  'contact.telegram',
  'contact.web',
  'action.copy',
  'action.open-external',
  'nav.home',
  'nav.stats',
  'nav.services',
  'nav.info',
  'settings',
  'notification',
];

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump();
  await tester.pump();
}

Widget _app(ThemeData theme, Widget child, {bool disableAnimations = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: c!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  test('the 13 new icon keys are registered with a file on disk', () {
    for (final k in _newKeys) {
      final icon = PicoIconRegistry.resolve(k);
      expect(icon, isNotNull, reason: k);
      expect(File(icon!.mono).existsSync(), isTrue, reason: icon.mono);
      expect(File(icon.duotone).existsSync(), isTrue, reason: icon.duotone);
      expect(icon.label('id'), isNotEmpty);
    }
    expect(PicoIconRegistry.keys.length, 41);
    expect(PicoIconRegistry.has('info'), isTrue);
  });

  test('every theme token in every SVG asset is substituted', () {
    final files = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'));
    expect(files, isNotEmpty);
    for (final f in files) {
      for (final b in Brightness.values) {
        final out = PicoSvgSource.themed(f.readAsStringSync(), b);
        expect(out.contains('var(--pico-'), isFalse, reason: '${f.path} $b');
      }
    }
    // Dark theme really swaps colours.
    final svg = File('assets/lottie/static/pico-loading.svg')
        .readAsStringSync();
    expect(
      PicoSvgSource.themed(svg, Brightness.dark),
      isNot(PicoSvgSource.themed(svg, Brightness.light)),
    );
  });

  testWidgets('PicoBrandIcon draws any key and falls back to info', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PicoTheme.light(),
        const Row(
          children: [
            PicoBrandIcon('nav.home'),
            PicoBrandIcon('no.such.key', duotone: true),
          ],
        ),
      ),
    );
    await _settle(tester);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets(
    'PicoLottie with animations disabled shows the SVG and no Lottie',
    (tester) async {
      for (final name in [
        'pico-loading',
        'pico-success',
        'pico-error',
        'pico-no-internet',
        'pico-vaccinated',
        'pico-logo-reveal',
      ]) {
        await tester.runAsync(
          () => PicoSvgSource.load(
            'assets/lottie/static/$name.svg',
            Brightness.light,
          ),
        );
        await tester.pumpWidget(
          _app(
            PicoTheme.light(),
            PicoLottie(name, width: 120, height: 120),
            disableAnimations: true,
          ),
        );
        await _settle(tester);
        expect(find.byType(SvgPicture), findsOneWidget, reason: name);
        expect(find.byType(LottieBuilder), findsNothing, reason: name);
      }
    },
  );

  testWidgets('PicoLottie with animations enabled builds a Lottie', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PicoTheme.light(),
        const PicoLottie('pico-loading', width: 120, height: 120),
      ),
    );
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('PicoSegmented reports the tapped value at 48 dp', (
    tester,
  ) async {
    var picked = 'a';
    await tester.pumpWidget(
      _app(
        PicoTheme.light(),
        StatefulBuilder(
          builder: (context, set) => PicoSegmented<String>(
            values: const ['a', 'b'],
            selected: picked,
            label: (v) => 'Pilih $v',
            onChanged: (v) => set(() => picked = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pilih b'));
    await tester.pump();
    expect(picked, 'b');
    expect(
      tester.getSize(find.byType(SegmentedButton<String>)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('PicoSectionHeader is a semantic header', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(PicoTheme.light(), const PicoSectionHeader(title: 'Statistik')),
    );
    expect(
      tester.getSemantics(find.text('Statistik')),
      matchesSemantics(label: 'Statistik', isHeader: true),
    );
    h.dispose();
  });

  for (final dark in [false, true]) {
    testGoldenSceneWithFonts('brand assets sample ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        for (final n in ['pico-state-empty']) {
          await PicoSvgSource.load(
            'assets/illustrations/$n.svg',
            dark ? Brightness.dark : Brightness.light,
          );
        }
      });
      await tester.pumpWidget(
        _app(
          dark ? PicoTheme.dark() : PicoTheme.light(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PicoSectionHeader(title: 'Ikon baru'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final k in _newKeys)
                    PicoBrandIcon(k, size: 32, duotone: k.hashCode.isEven),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    PicoWovenPlate(
                      size: 140,
                      child: PicoBrandIcon(
                        'facility.hospital',
                        size: 48,
                        duotone: true,
                      ),
                    ),
                    PicoIllustration(
                      'pico-state-empty',
                      width: 160,
                      height: 120,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PicoSegmented<int>(
                values: const [0, 1],
                selected: 0,
                label: (v) => v == 0 ? 'Harian' : 'Kumulatif',
                onChanged: (_) {},
              ),
            ],
          ),
          disableAnimations: true,
        ),
      );
      await _settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/brand_assets_${dark ? 'dark' : 'light'}.png',
        ),
      );
    }, tags: ['golden']);
  }
}
