import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

/// Test font family that uses locally loaded fonts.
const _testFontFamily = PicoFontFamily();

/// Font family constant for test widget labels.
const _labelFontFamily = 'SourceSans3';

void main() {
  group('PicoRadiusExtension Golden Tests', () {
    testGoldenSceneWithFonts('Radius - Scale Overview', (tester) async {
      final radius = PicoRadiusExtension.standard();

      tester.view.physicalSize = const Size(800, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildRadiusScale(radius));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/radius_scale.png'),
      );
    }, tags: ['golden', 'radius']);
  });
}

class const _RadiusData(final String label, final double value);

Widget _buildRadiusScale(PicoRadiusExtension radius) {
  final lightTheme = PicoTheme.light(fontFamily: _testFontFamily);
  final darkTheme = PicoTheme.dark(fontFamily: _testFontFamily);

  final radiusData = [
    _RadiusData('none', radius.none),
    _RadiusData('xs', radius.xs),
    _RadiusData('sm', radius.sm),
    _RadiusData('md', radius.md),
    _RadiusData('lg', radius.lg),
    _RadiusData('xl', radius.xl),
    _RadiusData('xl2', radius.xl2),
    _RadiusData('full', radius.full),
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
              'Border Radius: Light vs Dark',
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
                    child: _buildRadiusColumn(
                      'Light Theme',
                      lightTheme,
                      radiusData,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRadiusColumn(
                      'Dark Theme',
                      darkTheme,
                      radiusData,
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

Widget _buildRadiusColumn(
  String title,
  ThemeData theme,
  List<_RadiusData> items,
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
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map((data) => _buildRadiusItem(data, colorExtension))
              .toList(),
        ),
      ],
    ),
  );
}

Widget _buildRadiusItem(_RadiusData data, PicoColorExtension colors) =>
    SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.foreground.primary,
              borderRadius: BorderRadius.circular(
                data.value > 40 ? 40 : data.value,
              ),
              border: Border.all(
                color: colors.foreground.primary.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: _labelFontFamily,
              color: colors.foreground.main,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background.strong,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data.value >= 9999 ? 'full' : '${data.value.toInt()}px',
              style: TextStyle(
                fontSize: 10,
                fontFamily: _labelFontFamily,
                color: colors.foreground.subtle,
              ),
            ),
          ),
        ],
      ),
    );
