import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

/// Test font family that uses locally loaded fonts.
const _testFontFamily = PicoFontFamily(headingFontFamily: 'Archivo');

/// Font family constant for test widget labels.
const _labelFontFamily = 'SourceSans3';

void main() {
  group('PicoTypographyExtension Golden Tests', () {
    testGoldenSceneWithFonts('Typography - Display Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Display Styles', [
          _TypoItem('Large', 'display.large', typography.display.large),
          _TypoItem('Medium', 'display.medium', typography.display.medium),
          _TypoItem('Small', 'display.small', typography.display.small),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_display_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Heading Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Heading Styles', [
          _TypoItem('H1', 'heading.h1', typography.heading.h1),
          _TypoItem('H2', 'heading.h2', typography.heading.h2),
          _TypoItem('H3', 'heading.h3', typography.heading.h3),
          _TypoItem('H4', 'heading.h4', typography.heading.h4),
          _TypoItem('H5', 'heading.h5', typography.heading.h5),
          _TypoItem('H6', 'heading.h6', typography.heading.h6),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_heading_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Body Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Body Styles', [
          _TypoItem('Large', 'body.large', typography.body.large),
          _TypoItem('Regular', 'body.regular', typography.body.regular),
          _TypoItem('Small', 'body.small', typography.body.small),
          _TypoItem(
            'Large Medium',
            'body.largeMedium',
            typography.body.largeMedium,
          ),
          _TypoItem('Medium', 'body.medium', typography.body.medium),
          _TypoItem(
            'Small Medium',
            'body.smallMedium',
            typography.body.smallMedium,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_body_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Label Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 310);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Label Styles', [
          _TypoItem('Caption', 'label.caption', typography.label.caption),
          _TypoItem(
            'Caption Medium',
            'label.captionMedium',
            typography.label.captionMedium,
          ),
          _TypoItem('Overline', 'label.overline', typography.label.overline),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_label_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Button Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 330);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Button Styles', [
          _TypoItem('Large', 'button.large', typography.button.large),
          _TypoItem('Regular', 'button.regular', typography.button.regular),
          _TypoItem('Small', 'button.small', typography.button.small),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_button_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Code Comparison', (tester) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(800, 270);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTypographyComparison('Code Styles', [
          _TypoItem('Regular', 'code.regular', typography.code.regular),
          _TypoItem('Small', 'code.small', typography.code.small),
        ]),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_code_comparison.png'),
      );
    }, tags: ['golden', 'typography']);

    testGoldenSceneWithFonts('Typography - Complete Overview Comparison', (
      tester,
    ) async {
      final typography = PicoTypographyExtension.standard(
        fontFamily: _testFontFamily,
      );

      tester.view.physicalSize = const Size(1200, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildOverviewComparison(typography));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/typography_overview_comparison.png'),
      );
    }, tags: ['golden', 'typography']);
  });
}

class const _TypoItem(
  final String label,
  final String className,
  final TextStyle style,
);

Widget _buildTypographyComparison(String title, List<_TypoItem> items) {
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
            Text(
              '$title: Light vs Dark',
              style: const TextStyle(
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
                    child: _buildTypoColumn('Light Theme', lightTheme, items),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypoColumn('Dark Theme', darkTheme, items),
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

Widget _buildTypoColumn(String title, ThemeData theme, List<_TypoItem> items) {
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
        ...items.map((item) => _buildTypoItem(item, colorExtension)),
      ],
    ),
  );
}

Widget _buildTypoItem(_TypoItem item, PicoColorExtension colors) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background.strong,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.className,
              style: TextStyle(
                fontSize: 10,
                fontFamily: _labelFontFamily,
                color: colors.foreground.subtle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: _labelFontFamily,
              color: colors.foreground.muted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatStyleInfo(item.style),
            style: TextStyle(
              fontSize: 9,
              fontFamily: _labelFontFamily,
              color: colors.foreground.muted,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'The quick brown fox',
        style: item.style.copyWith(color: colors.foreground.main),
      ),
    ],
  ),
);

String _formatStyleInfo(TextStyle style) {
  final parts = <String>[];
  if (style.fontSize != null) {
    parts.add('${style.fontSize!.toInt()}px');
  }
  if (style.fontWeight != null) {
    parts.add('w${style.fontWeight!.value}');
  }
  if (style.height != null) {
    parts.add('h${style.height}');
  }
  return parts.join(' · ');
}

Widget _buildOverviewComparison(PicoTypographyExtension typography) {
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
              'Typography System: Light vs Dark',
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
                  Expanded(child: _buildOverviewColumn(typography, lightTheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOverviewColumn(typography, darkTheme)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildOverviewColumn(
  PicoTypographyExtension typography,
  ThemeData theme,
) {
  final colorExtension = theme.extension<PicoColorExtension>()!;
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    padding: const EdgeInsets.all(12),
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
          isDark ? 'Dark Theme' : 'Light Theme',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: _labelFontFamily,
            color: colorExtension.foreground.main,
          ),
        ),
        const SizedBox(height: 10),
        _buildOverviewSection('Display', colorExtension, [
          _OverviewRow('Large', typography.display.large),
          _OverviewRow('Medium', typography.display.medium),
          _OverviewRow('Small', typography.display.small),
        ]),
        _buildOverviewSection('Heading', colorExtension, [
          _OverviewRow('H1', typography.heading.h1),
          _OverviewRow('H2', typography.heading.h2),
          _OverviewRow('H3', typography.heading.h3),
          _OverviewRow('H4', typography.heading.h4),
          _OverviewRow('H5', typography.heading.h5),
          _OverviewRow('H6', typography.heading.h6),
        ]),
        _buildOverviewSection('Body', colorExtension, [
          _OverviewRow('Large', typography.body.large),
          _OverviewRow('Regular', typography.body.regular),
          _OverviewRow('Small', typography.body.small),
        ]),
        _buildOverviewSection('Label', colorExtension, [
          _OverviewRow('Caption', typography.label.caption),
          _OverviewRow('Overline', typography.label.overline),
        ]),
        _buildOverviewSection('Button', colorExtension, [
          _OverviewRow('Large', typography.button.large),
          _OverviewRow('Regular', typography.button.regular),
          _OverviewRow('Small', typography.button.small),
        ]),
        _buildOverviewSection('Code', colorExtension, [
          _OverviewRow('Regular', typography.code.regular),
          _OverviewRow('Small', typography.code.small),
        ]),
      ],
    ),
  );
}

class const _OverviewRow(final String label, final TextStyle style);

Widget _buildOverviewSection(
  String title,
  PicoColorExtension colors,
  List<_OverviewRow> rows,
) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colors.foreground.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: _labelFontFamily,
            color: colors.foreground.primary,
          ),
        ),
      ),
      const SizedBox(height: 6),
      ...rows.map(
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: _labelFontFamily,
                    color: colors.foreground.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Aa Bb',
                  style: row.style.copyWith(color: colors.foreground.main),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
