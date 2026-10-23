import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

/// Test font family that uses locally loaded fonts.
const _testFontFamily = PicoFontFamily();

/// Font family constant for test widget labels.
const _labelFontFamily = 'SourceSans3';

void main() {
  group('PicoSpacingExtension Golden Tests', () {
    testGoldenSceneWithFonts('Spacing - Scale Overview', (tester) async {
      final spacing = PicoSpacingExtension.standard();

      tester.view.physicalSize = const Size(600, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildSpacingScale(spacing));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/spacing_scale.png'),
      );
    }, tags: ['golden', 'spacing']);
  });
}

class const _SpacingData(
  final String label,
  final double value,
  final String multiplier,
);

Widget _buildSpacingScale(PicoSpacingExtension spacing) {
  final lightTheme = PicoTheme.light(fontFamily: _testFontFamily);
  final darkTheme = PicoTheme.dark(fontFamily: _testFontFamily);

  final spacingData = [
    _SpacingData('none', spacing.none, '0x'),
    _SpacingData('xxs', spacing.xxs, '0.5x'),
    _SpacingData('xs', spacing.xs, '1x'),
    _SpacingData('sm', spacing.sm, '2x'),
    _SpacingData('md', spacing.md, '3x'),
    _SpacingData('lg', spacing.lg, '4x'),
    _SpacingData('xl', spacing.xl, '6x'),
    _SpacingData('xl2', spacing.xl2, '8x'),
    _SpacingData('xl3', spacing.xl3, '12x'),
    _SpacingData('xl4', spacing.xl4, '16x'),
    _SpacingData('xl5', spacing.xl5, '20x'),
    _SpacingData('xl6', spacing.xl6, '24x'),
  ];

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Spacing Scale: Light vs Dark',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: _labelFontFamily,
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildSpacingColumn(
                      'Light Theme',
                      lightTheme,
                      spacingData,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSpacingColumn(
                      'Dark Theme',
                      darkTheme,
                      spacingData,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSpacingColumn(
  String title,
  ThemeData theme,
  List<_SpacingData> items,
) {
  final colorExtension = theme.extension<PicoColorExtension>()!;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorExtension.background.main,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: _labelFontFamily,
            color: colorExtension.foreground.main,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((data) => _buildSpacingRow(data, colorExtension)),
      ],
    ),
  );
}

Widget _buildSpacingRow(_SpacingData data, PicoColorExtension colors) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: _labelFontFamily,
                color: colors.foreground.main,
              ),
            ),
          ),
          Container(
            width: data.value,
            height: 24,
            decoration: BoxDecoration(
              color: colors.foreground.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.background.strong,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${data.value.toInt()}px',
              style: TextStyle(
                fontSize: 11,
                fontFamily: _labelFontFamily,
                fontWeight: FontWeight.w500,
                color: colors.foreground.subtle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.multiplier,
            style: TextStyle(
              fontSize: 10,
              fontFamily: _labelFontFamily,
              color: colors.foreground.muted,
            ),
          ),
        ],
      ),
    );
