import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

/// Test font family that uses locally loaded fonts.
const _testFontFamily = PicoFontFamily(headingFontFamily: 'Archivo');

/// Font family constant for test widget labels.
const _labelFontFamily = 'SourceSans3';

void main() {
  group('PicoShadowExtension Golden Tests', () {
    testGoldenSceneWithFonts('Shadows - Comparison', (tester) async {
      final lightShadows = PicoShadowExtension.light();
      final darkShadows = PicoShadowExtension.dark();

      tester.view.physicalSize = const Size(1200, 530);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildShadowComparison(lightShadows, darkShadows),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/shadows_comparison.png'),
      );
    }, tags: ['golden', 'shadows']);
  });
}

class const _ShadowData(
  final String label,
  final String className,
  final List<BoxShadow> shadows,
);

Widget _buildShadowComparison(
  PicoShadowExtension light,
  PicoShadowExtension dark,
) {
  final lightTheme = PicoTheme.light(fontFamily: _testFontFamily);
  final darkTheme = PicoTheme.dark(fontFamily: _testFontFamily);

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
              'Shadows: Light vs Dark',
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
                    child: _buildShadowColumn('Light Theme', lightTheme, [
                      _ShadowData('None', 'none', light.none),
                      _ShadowData('XS', 'xs', light.xs),
                      _ShadowData('SM', 'sm', light.sm),
                      _ShadowData('MD', 'md', light.md),
                      _ShadowData('LG', 'lg', light.lg),
                      _ShadowData('XL', 'xl', light.xl),
                      _ShadowData('2XL', 'xl2', light.xl2),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildShadowColumn('Dark Theme', darkTheme, [
                      _ShadowData('None', 'none', dark.none),
                      _ShadowData('XS', 'xs', dark.xs),
                      _ShadowData('SM', 'sm', dark.sm),
                      _ShadowData('MD', 'md', dark.md),
                      _ShadowData('LG', 'lg', dark.lg),
                      _ShadowData('XL', 'xl', dark.xl),
                      _ShadowData('2XL', 'xl2', dark.xl2),
                    ]),
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

Widget _buildShadowColumn(
  String title,
  ThemeData theme,
  List<_ShadowData> items,
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
          spacing: 12,
          runSpacing: 16,
          children: items
              .map((item) => _buildShadowItem(item, colorExtension))
              .toList(),
        ),
      ],
    ),
  );
}

Widget _buildShadowItem(_ShadowData item, PicoColorExtension colors) =>
    SizedBox(
      width: 110,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: colors.background.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outline.main),
              boxShadow: item.shadows,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
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
              item.className,
              style: TextStyle(
                fontSize: 9,
                fontFamily: _labelFontFamily,
                color: colors.foreground.subtle,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatShadowInfo(item.shadows),
            style: TextStyle(
              fontSize: 9,
              fontFamily: _labelFontFamily,
              color: colors.foreground.muted,
            ),
          ),
        ],
      ),
    );

String _formatShadowInfo(List<BoxShadow> shadows) {
  if (shadows.isEmpty) return 'no shadow';
  final shadow = shadows.first;
  return 'blur: ${shadow.blurRadius.toInt()}  y: ${shadow.offset.dy.toInt()}';
}
