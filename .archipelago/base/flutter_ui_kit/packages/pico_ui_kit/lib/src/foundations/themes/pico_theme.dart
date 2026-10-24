import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_token.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_asset_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_shadow_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_font_family.dart';

/// Main theme factory for the design system.
abstract final class PicoTheme() {
  /// Creates the light theme.
  static ThemeData light({PicoFontFamily? fontFamily}) {
    final fonts = fontFamily ?? const PicoFontFamily();
    final colorExtension = PicoColorExtension.light();
    final typographyExtension = PicoTypographyExtension.standard(
      fontFamily: fonts,
    );
    final shadowExtension = PicoShadowExtension.light();
    final spacingExtension = PicoSpacingExtension.standard();
    final radiusExtension = PicoRadiusExtension.standard();
    final assetExtension = PicoAssetExtension.instance();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fonts.isUsingCustomFonts ? fonts.bodyFontFamily : null,
      colorScheme: ColorScheme.light(
        primary: colorExtension.action.primary.active,
        primaryContainer: PicoColorToken.primary100,
        onPrimaryContainer: PicoColorToken.primary900,
        secondary: PicoColorToken.secondary600,
        secondaryContainer: PicoColorToken.secondary100,
        onSecondaryContainer: PicoColorToken.secondary900,
        tertiary: PicoColorToken.tertiary600,
        tertiaryContainer: PicoColorToken.tertiary100,
        onTertiaryContainer: PicoColorToken.tertiary900,
        error: colorExtension.action.destructive.active,
        errorContainer: PicoColorToken.error100,
        onErrorContainer: PicoColorToken.error900,
        surface: colorExtension.background.main,
        onSurface: colorExtension.foreground.main,
        outline: colorExtension.outline.main,
        outlineVariant: colorExtension.outline.subtle,
      ),
      textTheme: fonts.applyToTextTheme(_buildTextTheme(typographyExtension)),
      scaffoldBackgroundColor: colorExtension.background.main,
      extensions: [
        colorExtension,
        typographyExtension,
        shadowExtension,
        spacingExtension,
        radiusExtension,
        assetExtension,
      ],
    );
  }

  /// Creates the dark theme.
  static ThemeData dark({PicoFontFamily? fontFamily}) {
    final fonts = fontFamily ?? const PicoFontFamily();
    final colorExtension = PicoColorExtension.dark();
    final typographyExtension = PicoTypographyExtension.standard(
      fontFamily: fonts,
    );
    final shadowExtension = PicoShadowExtension.dark();
    final spacingExtension = PicoSpacingExtension.standard();
    final radiusExtension = PicoRadiusExtension.standard();
    final assetExtension = PicoAssetExtension.instance();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fonts.isUsingCustomFonts ? fonts.bodyFontFamily : null,
      colorScheme: ColorScheme.dark(
        primary: PicoColorToken.primary400,
        onPrimary: PicoColorToken.primary950,
        primaryContainer: PicoColorToken.primary800,
        onPrimaryContainer: PicoColorToken.primary100,
        secondary: PicoColorToken.secondary400,
        tertiary: PicoColorToken.tertiary400,
        error: PicoColorToken.error400,
        surface: colorExtension.background.main,
        onSurface: colorExtension.foreground.main,
        outline: colorExtension.outline.main,
        outlineVariant: colorExtension.outline.subtle,
      ),
      textTheme: fonts.applyToTextTheme(_buildTextTheme(typographyExtension)),
      scaffoldBackgroundColor: colorExtension.background.main,
      extensions: [
        colorExtension,
        typographyExtension,
        shadowExtension,
        spacingExtension,
        radiusExtension,
        assetExtension,
      ],
    );
  }

  static TextTheme _buildTextTheme(PicoTypographyExtension typography) =>
      TextTheme(
        displayLarge: typography.display.large,
        displayMedium: typography.display.medium,
        displaySmall: typography.display.small,
        headlineLarge: typography.heading.h1,
        headlineMedium: typography.heading.h2,
        headlineSmall: typography.heading.h3,
        titleLarge: typography.heading.h4,
        titleMedium: typography.heading.h5,
        titleSmall: typography.heading.h6,
        bodyLarge: typography.body.large,
        bodyMedium: typography.body.regular,
        bodySmall: typography.body.small,
        labelLarge: typography.button.regular,
        labelMedium: typography.label.caption,
        labelSmall: typography.label.overline,
      );
}
