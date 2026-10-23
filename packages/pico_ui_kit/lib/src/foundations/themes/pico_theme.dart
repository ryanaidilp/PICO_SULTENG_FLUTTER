import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';
import 'package:pico_ui_kit/src/foundations/radius/pico_radius_token.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_asset_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_shadow_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_font_family.dart';

/// Main theme factory for the design system (ADR-0106: Tenun brand on a
/// Material 3 base). Elevation is 0 everywhere, depth comes from rules and
/// cloth, and the surface tint is transparent so M3 tonal elevation never leaks.
abstract final class PicoTheme() {
  /// Creates the light theme.
  static ThemeData light({PicoFontFamily? fontFamily}) =>
      _build(Brightness.light, fontFamily);

  /// Creates the dark theme.
  static ThemeData dark({PicoFontFamily? fontFamily}) =>
      _build(Brightness.dark, fontFamily);

  static ThemeData _build(Brightness brightness, PicoFontFamily? fontFamily) {
    final isDark = brightness == Brightness.dark;
    final fonts = fontFamily ?? const PicoFontFamily();
    final colors = isDark
        ? PicoColorExtension.dark()
        : PicoColorExtension.light();
    final typography = PicoTypographyExtension.standard(fontFamily: fonts);
    // Secondary is crimson (one crimson per view, DESIGN.md), so selected
    // M3 containers use the cloth tint instead of a crimson wash.
    final scheme = (isDark ? PicoColorSchemes.dark : PicoColorSchemes.light)
        .copyWith(
          secondaryContainer: isDark
              ? PicoBrandPalette.tintDark
              : PicoBrandPalette.tintLight,
          onSecondaryContainer: isDark
              ? PicoBrandPalette.indigoDark
              : PicoBrandPalette.indigoLight,
          surfaceContainerHighest: colors.background.subtle,
        );
    final textTheme = fonts.applyToTextTheme(_buildTextTheme(typography));
    const shape = RoundedRectangleBorder(
      borderRadius: PicoRadiusToken.borderMd,
    );
    final nav = isDark ? colors.background.subtle : colors.background.inverse;
    final onNav = isDark ? colors.foreground.main : colors.foreground.inverse;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fonts.bodyFontFamily,
      fontFamilyFallback: const <String>[],
      package: fonts.package,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background.main,
      canvasColor: colors.background.main,
      dividerColor: colors.outline.subtle,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background.main,
        foregroundColor: colors.foreground.main,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.heading.h4.copyWith(
          color: colors.foreground.main,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.background.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: PicoRadiusToken.borderMd,
          side: BorderSide(color: colors.outline.subtle),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.background.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: PicoRadiusToken.borderLg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.background.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: PicoRadiusToken.radiusLg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: shape,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shape,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: colors.outline.main),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: shape,
          minimumSize: const Size(48, 48),
        ),
      ),
      // Selvedge band: indigo ground (light), sky indicator, paper labels.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nav,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? PicoBrandPalette.tintDark
            : PicoBrandPalette.skyLight,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: PicoRadiusToken.borderSm,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) && !isDark
                ? PicoBrandPalette.indigoLight
                : onNav,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          typography.label.caption.copyWith(color: onNav),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: shape,
          minimumSize: const Size(48, 48),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        colors,
        typography,
        if (isDark) PicoShadowExtension.dark() else PicoShadowExtension.light(),
        PicoSpacingExtension.standard(),
        PicoRadiusExtension.standard(),
        PicoAssetExtension.instance(),
        if (isDark) PicoStateColors.dark else PicoStateColors.light,
        if (isDark) PicoClothSurface.dark else PicoClothSurface.light,
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
