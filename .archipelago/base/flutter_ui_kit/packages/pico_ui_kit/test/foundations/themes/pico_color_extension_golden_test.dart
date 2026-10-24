import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';
import '../../util/color_item.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'Plus Jakarta Sans';

/// Semantic color entry with label and color value.
/// Token name is auto-resolved by scanning all known palettes.
class const _ColorEntry(final String label, final Color color);

void main() {
  group('PicoColorExtension Golden Tests', () {
    testGoldenSceneWithFonts('Semantic Colors - Comparison', (tester) async {
      final lightColors = PicoColorExtension.light();
      final darkColors = PicoColorExtension.dark();

      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildColorComparisonWidget(lightColors, darkColors),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/semantic_colors_comparison.png'),
      );
    }, tags: ['golden', 'colors', 'theme']);

    testGoldenSceneWithFonts('Color Tokens - All Palettes', (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildColorTokensWidget());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('./goldens/color_tokens_all.png'),
      );
    }, tags: ['golden', 'colors']);
  });
}

Widget _buildColorComparisonWidget(
  PicoColorExtension light,
  PicoColorExtension dark,
) => MaterialApp(
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
            'Semantic Colors: Light vs Dark',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: _testFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildComparisonColumn(
                    'Light Theme',
                    _buildLightColorEntries(light),
                    false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComparisonColumn(
                    'Dark Theme',
                    _buildDarkColorEntries(dark),
                    true,
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

/// Builds color entries for light theme — token names auto-resolved.
Map<String, List<_ColorEntry>> _buildLightColorEntries(
  PicoColorExtension colors,
) => {
  'Background': [
    _ColorEntry('Main', colors.background.main),
    _ColorEntry('Subtle', colors.background.subtle),
    _ColorEntry('Strong', colors.background.strong),
    _ColorEntry('Inverse', colors.background.inverse),
    _ColorEntry('Card', colors.background.card),
    _ColorEntry('Card Sec', colors.background.cardSecondary),
    _ColorEntry('Success', colors.background.success),
    _ColorEntry('Warning', colors.background.warning),
    _ColorEntry('Error', colors.background.error),
    _ColorEntry('Info', colors.background.info),
  ],
  'Foreground': [
    _ColorEntry('Main', colors.foreground.main),
    _ColorEntry('Subtle', colors.foreground.subtle),
    _ColorEntry('Muted', colors.foreground.muted),
    _ColorEntry('Disabled', colors.foreground.disabled),
    _ColorEntry('Inverse', colors.foreground.inverse),
    _ColorEntry('Primary', colors.foreground.primary),
    _ColorEntry('Success', colors.foreground.success),
    _ColorEntry('Warning', colors.foreground.warning),
    _ColorEntry('Error', colors.foreground.error),
    _ColorEntry('Info', colors.foreground.info),
  ],
  'Action Primary': [
    _ColorEntry('Active', colors.action.primary.active),
    _ColorEntry('Hover', colors.action.primary.hover),
    _ColorEntry('Disabled', colors.action.primary.disabled),
  ],
  'Action Secondary': [
    _ColorEntry('Active', colors.action.secondary.active),
    _ColorEntry('Hover', colors.action.secondary.hover),
    _ColorEntry('Disabled', colors.action.secondary.disabled),
  ],
  'Action Destructive': [
    _ColorEntry('Active', colors.action.destructive.active),
    _ColorEntry('Hover', colors.action.destructive.hover),
    _ColorEntry('Disabled', colors.action.destructive.disabled),
  ],
  'Action Success': [
    _ColorEntry('Active', colors.action.success.active),
    _ColorEntry('Hover', colors.action.success.hover),
    _ColorEntry('Disabled', colors.action.success.disabled),
  ],
  'Outline': [
    _ColorEntry('Main', colors.outline.main),
    _ColorEntry('Strong', colors.outline.strong),
    _ColorEntry('Subtle', colors.outline.subtle),
    _ColorEntry('Focus', colors.outline.focus),
  ],
  'Overlay': [_ColorEntry('Overlay', colors.overlay)],
};

/// Builds color entries for dark theme — token names auto-resolved.
Map<String, List<_ColorEntry>> _buildDarkColorEntries(
  PicoColorExtension colors,
) => {
  'Background': [
    _ColorEntry('Main', colors.background.main),
    _ColorEntry('Subtle', colors.background.subtle),
    _ColorEntry('Strong', colors.background.strong),
    _ColorEntry('Inverse', colors.background.inverse),
    _ColorEntry('Card', colors.background.card),
    _ColorEntry('Card Sec', colors.background.cardSecondary),
    _ColorEntry('Success', colors.background.success),
    _ColorEntry('Warning', colors.background.warning),
    _ColorEntry('Error', colors.background.error),
    _ColorEntry('Info', colors.background.info),
  ],
  'Foreground': [
    _ColorEntry('Main', colors.foreground.main),
    _ColorEntry('Subtle', colors.foreground.subtle),
    _ColorEntry('Muted', colors.foreground.muted),
    _ColorEntry('Disabled', colors.foreground.disabled),
    _ColorEntry('Inverse', colors.foreground.inverse),
    _ColorEntry('Primary', colors.foreground.primary),
    _ColorEntry('Success', colors.foreground.success),
    _ColorEntry('Warning', colors.foreground.warning),
    _ColorEntry('Error', colors.foreground.error),
    _ColorEntry('Info', colors.foreground.info),
  ],
  'Action Primary': [
    _ColorEntry('Active', colors.action.primary.active),
    _ColorEntry('Hover', colors.action.primary.hover),
    _ColorEntry('Disabled', colors.action.primary.disabled),
  ],
  'Action Secondary': [
    _ColorEntry('Active', colors.action.secondary.active),
    _ColorEntry('Hover', colors.action.secondary.hover),
    _ColorEntry('Disabled', colors.action.secondary.disabled),
  ],
  'Action Destructive': [
    _ColorEntry('Active', colors.action.destructive.active),
    _ColorEntry('Hover', colors.action.destructive.hover),
    _ColorEntry('Disabled', colors.action.destructive.disabled),
  ],
  'Action Success': [
    _ColorEntry('Active', colors.action.success.active),
    _ColorEntry('Hover', colors.action.success.hover),
    _ColorEntry('Disabled', colors.action.success.disabled),
  ],
  'Outline': [
    _ColorEntry('Main', colors.outline.main),
    _ColorEntry('Strong', colors.outline.strong),
    _ColorEntry('Subtle', colors.outline.subtle),
    _ColorEntry('Focus', colors.outline.focus),
  ],
  'Overlay': [_ColorEntry('Overlay', colors.overlay)],
};

Widget _buildComparisonColumn(
  String title,
  Map<String, List<_ColorEntry>> sections,
  bool isDark,
) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF121212) : Colors.white,
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
          fontFamily: _testFontFamily,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      const SizedBox(height: 10),
      for (final entry in sections.entries)
        _buildComparisonSection(entry.key, isDark, entry.value),
    ],
  ),
);

Widget _buildComparisonSection(
  String title,
  bool isDark,
  List<_ColorEntry> entries,
) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: _testFontFamily,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: entries
            .map(
              (e) => _ComparisonSwatch(
                label: e.label,
                color: e.color,
                isDark: isDark,
              ),
            )
            .toList(),
      ),
    ],
  ),
);

class const _ComparisonSwatch({
  required final String label,
  required final Color color,
  required final bool isDark,
}) extends StatelessWidget {
  String get _tokenName => autoResolveTokenName(color);

  String get _hexCode {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: _testFontFamily,
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _tokenName,
          style: TextStyle(
            fontSize: 8,
            fontFamily: _testFontFamily,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _hexCode,
          style: TextStyle(
            fontSize: 7,
            fontFamily: _testFontFamily,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(ColorProperty('color', color));
    properties.add(DiagnosticsProperty<bool>('isDark', isDark));
  }
}

Widget _buildColorTokensWidget() => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    backgroundColor: Colors.white,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Color Token Palettes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: _testFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          _buildTokenSubsection('Primary', {
            '50': PicoColorToken.primary50,
            '100': PicoColorToken.primary100,
            '200': PicoColorToken.primary200,
            '300': PicoColorToken.primary300,
            '400': PicoColorToken.primary400,
            '500': PicoColorToken.primary500,
            '600': PicoColorToken.primary600,
            '700': PicoColorToken.primary700,
            '800': PicoColorToken.primary800,
            '900': PicoColorToken.primary900,
            '950': PicoColorToken.primary950,
          }),
          _buildTokenSubsection('Slate (Neutral)', {
            '50': PicoColorToken.slate50,
            '100': PicoColorToken.slate100,
            '200': PicoColorToken.slate200,
            '300': PicoColorToken.slate300,
            '400': PicoColorToken.slate400,
            '500': PicoColorToken.slate500,
            '600': PicoColorToken.slate600,
            '700': PicoColorToken.slate700,
            '800': PicoColorToken.slate800,
            '900': PicoColorToken.slate900,
            '950': PicoColorToken.slate950,
          }),
          _buildTokenSubsection('Secondary (Cyan)', {
            '50': PicoColorToken.secondary50,
            '100': PicoColorToken.secondary100,
            '200': PicoColorToken.secondary200,
            '300': PicoColorToken.secondary300,
            '400': PicoColorToken.secondary400,
            '500': PicoColorToken.secondary500,
            '600': PicoColorToken.secondary600,
            '700': PicoColorToken.secondary700,
            '800': PicoColorToken.secondary800,
            '900': PicoColorToken.secondary900,
            '950': PicoColorToken.secondary950,
          }),
          _buildTokenSubsection('Tertiary (Amber)', {
            '50': PicoColorToken.tertiary50,
            '100': PicoColorToken.tertiary100,
            '200': PicoColorToken.tertiary200,
            '300': PicoColorToken.tertiary300,
            '400': PicoColorToken.tertiary400,
            '500': PicoColorToken.tertiary500,
            '600': PicoColorToken.tertiary600,
            '700': PicoColorToken.tertiary700,
            '800': PicoColorToken.tertiary800,
            '900': PicoColorToken.tertiary900,
            '950': PicoColorToken.tertiary950,
          }),
          _buildTokenSubsection('Success', {
            '50': PicoColorToken.success50,
            '100': PicoColorToken.success100,
            '200': PicoColorToken.success200,
            '300': PicoColorToken.success300,
            '400': PicoColorToken.success400,
            '500': PicoColorToken.success500,
            '600': PicoColorToken.success600,
            '700': PicoColorToken.success700,
            '800': PicoColorToken.success800,
            '900': PicoColorToken.success900,
            '950': PicoColorToken.success950,
          }),
          _buildTokenSubsection('Warning', {
            '50': PicoColorToken.warning50,
            '100': PicoColorToken.warning100,
            '200': PicoColorToken.warning200,
            '300': PicoColorToken.warning300,
            '400': PicoColorToken.warning400,
            '500': PicoColorToken.warning500,
            '600': PicoColorToken.warning600,
            '700': PicoColorToken.warning700,
            '800': PicoColorToken.warning800,
            '900': PicoColorToken.warning900,
            '950': PicoColorToken.warning950,
          }),
          _buildTokenSubsection('Error', {
            '50': PicoColorToken.error50,
            '100': PicoColorToken.error100,
            '200': PicoColorToken.error200,
            '300': PicoColorToken.error300,
            '400': PicoColorToken.error400,
            '500': PicoColorToken.error500,
            '600': PicoColorToken.error600,
            '700': PicoColorToken.error700,
            '800': PicoColorToken.error800,
            '900': PicoColorToken.error900,
            '950': PicoColorToken.error950,
          }),
          _buildTokenSubsection('Info', {
            '50': PicoColorToken.info50,
            '100': PicoColorToken.info100,
            '200': PicoColorToken.info200,
            '300': PicoColorToken.info300,
            '400': PicoColorToken.info400,
            '500': PicoColorToken.info500,
            '600': PicoColorToken.info600,
            '700': PicoColorToken.info700,
            '800': PicoColorToken.info800,
            '900': PicoColorToken.info900,
            '950': PicoColorToken.info950,
          }),
        ],
      ),
    ),
  ),
);

Widget _buildTokenSubsection(String title, Map<String, Color> colors) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: _testFontFamily,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: colors.entries
                .map((e) => _TokenSwatch(label: e.key, color: e.value))
                .toList(),
          ),
        ],
      ),
    );

class const _TokenSwatch({
  required final String label,
  required final Color color,
}) extends StatelessWidget {
  String get _tokenName => autoResolveTokenName(color);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _tokenName,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: _testFontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(ColorProperty('color', color));
  }
}
