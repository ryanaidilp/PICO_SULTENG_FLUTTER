import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';
import '../../util/contrast_checker.dart';

const _testFontFamily = 'Plus Jakarta Sans';

void main() {
  group('Contrast Ratio Golden Tests', () {
    testGoldenSceneWithFonts('WCAG Contrast - Light Theme', (tester) async {
      final colors = PicoColorExtension.light();

      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildContrastWidget('Light Theme', colors, false),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/contrast_light.png'),
      );
    }, tags: ['golden', 'colors', 'contrast']);

    testGoldenSceneWithFonts('WCAG Contrast - Dark Theme', (tester) async {
      final colors = PicoColorExtension.dark();

      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildContrastWidget('Dark Theme', colors, true));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/contrast_dark.png'),
      );
    }, tags: ['golden', 'colors', 'contrast']);
  });
}

Widget _buildContrastWidget(
  String title,
  PicoColorExtension colors,
  bool isDark,
) {
  final pairs = _buildContrastPairs(colors);

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WCAG Contrast Check — $title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: _testFontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AAA >= 7.0:1  |  AA >= 4.5:1  |  FAIL < 4.5:1',
              style: TextStyle(
                fontSize: 11,
                fontFamily: _testFontFamily,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            for (final section in pairs.entries) ...[
              Text(
                section.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _testFontFamily,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: section.value
                    .map((p) => ContrastPairWidget(pair: p))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    ),
  );
}

Map<String, List<ContrastPair>> _buildContrastPairs(
  PicoColorExtension colors,
) => {
  'Text on Background': [
    ContrastPair(
      label: 'Main text on Main bg',
      foreground: colors.foreground.main,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Subtle text on Main bg',
      foreground: colors.foreground.subtle,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Muted text on Main bg',
      foreground: colors.foreground.muted,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Main text on Card bg',
      foreground: colors.foreground.main,
      background: colors.background.card,
    ),
    ContrastPair(
      label: 'Subtle text on Card bg',
      foreground: colors.foreground.subtle,
      background: colors.background.card,
    ),
    ContrastPair(
      label: 'Main text on Subtle bg',
      foreground: colors.foreground.main,
      background: colors.background.subtle,
    ),
    ContrastPair(
      label: 'Inverse text on Inverse bg',
      foreground: colors.foreground.inverse,
      background: colors.background.inverse,
    ),
  ],
  'Actions on Background': [
    ContrastPair(
      label: 'Primary on Main bg',
      foreground: colors.action.primary.active,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Primary on Card bg',
      foreground: colors.action.primary.active,
      background: colors.background.card,
    ),
    ContrastPair(
      label: 'Secondary on Main bg',
      foreground: colors.action.secondary.active,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Destructive on Main bg',
      foreground: colors.action.destructive.active,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Success on Main bg',
      foreground: colors.action.success.active,
      background: colors.background.main,
    ),
  ],
  'Semantic Foreground on Status': [
    ContrastPair(
      label: 'Success fg on Success bg',
      foreground: colors.foreground.success,
      background: colors.background.success,
    ),
    ContrastPair(
      label: 'Warning fg on Warning bg',
      foreground: colors.foreground.warning,
      background: colors.background.warning,
    ),
    ContrastPair(
      label: 'Error fg on Error bg',
      foreground: colors.foreground.error,
      background: colors.background.error,
    ),
    ContrastPair(
      label: 'Info fg on Info bg',
      foreground: colors.foreground.info,
      background: colors.background.info,
    ),
  ],
  'Button Text': [
    ContrastPair(
      label: 'White on Primary btn',
      foreground: PicoColorToken.white,
      background: colors.action.primary.active,
    ),
    ContrastPair(
      label: 'White on Secondary btn',
      foreground: PicoColorToken.white,
      background: colors.action.secondary.active,
    ),
    ContrastPair(
      label: 'White on Destructive btn',
      foreground: PicoColorToken.white,
      background: colors.action.destructive.active,
    ),
    ContrastPair(
      label: 'White on Success btn',
      foreground: PicoColorToken.white,
      background: colors.action.success.active,
    ),
  ],
  'Outline Visibility': [
    ContrastPair(
      label: 'Outline on Main bg',
      foreground: colors.outline.main,
      background: colors.background.main,
    ),
    ContrastPair(
      label: 'Outline on Card bg',
      foreground: colors.outline.main,
      background: colors.background.card,
    ),
    ContrastPair(
      label: 'Strong outline on Main bg',
      foreground: colors.outline.strong,
      background: colors.background.main,
    ),
  ],
};
