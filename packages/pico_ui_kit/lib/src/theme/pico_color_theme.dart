import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/style/colors/pico_color_data.dart';
import 'package:pico_ui_kit/src/style/pico_colors.dart';

class PicoColorTheme extends ThemeExtension<PicoColorTheme> {
  PicoColorTheme._({
    required this.background,
    required this.text,
    required this.semantic,
  });

  factory PicoColorTheme.light() => PicoColorTheme._(
        background: PicoBackgroundNeutral(
          main: PicoColors.bgMain,
          subtle: PicoColors.bgSubtle,
          strong: PicoColors.bgStrong,
          white: PicoColors.bgWhite,
          inverse: PicoColors.bgInverse,
        ),
        text: PicoTextNeutral(
          main: PicoColors.textMain,
          subtle: PicoColors.textSubtle,
          strong: PicoColors.textStrong,
          disabled: PicoColors.textDisabled,
          inverse: PicoColors.textInverse,
          onImageStrong: PicoColors.textOnImageStrong,
          onImageSubtle: PicoColors.textOnImageSubtle,
        ),
        semantic: const PicoSemanticColor(
          info: PicoColors.info,
          error: PicoColors.error,
          success: PicoColors.success,
          warning: PicoColors.warning,
        ),
      );

  factory PicoColorTheme.dark() => PicoColorTheme._(
        background: PicoBackgroundNeutral(
          main: PicoColors.bgMainDark,
          subtle: PicoColors.bgSubtleDark,
          strong: PicoColors.bgStrongDark,
          white: PicoColors.bgWhiteDark,
          inverse: PicoColors.bgInverseDark,
        ),
        text: PicoTextNeutral(
          main: PicoColors.textMain,
          subtle: PicoColors.textSubtle,
          strong: PicoColors.textStrong,
          disabled: PicoColors.textDisabled,
          inverse: PicoColors.textInverse,
          onImageStrong: PicoColors.textOnImageStrong,
          onImageSubtle: PicoColors.textOnImageSubtle,
        ),
        semantic: const PicoSemanticColor(
          info: PicoColors.info,
          error: PicoColors.error,
          success: PicoColors.success,
          warning: PicoColors.warning,
        ),
      );

  final PicoBackgroundNeutral background;
  final PicoForegroundNeutral text;
  final PicoSemanticColor semantic;

  @override
  ThemeExtension<PicoColorTheme> copyWith({
    PicoBackgroundNeutral? backgroundVariant,
    PicoTextNeutral? foregroundVariant,
    PicoSemanticColor? semanticVariant,
  }) =>
      PicoColorTheme._(
        background: background.copyWith(
          main: backgroundVariant?.main,
          inverse: backgroundVariant?.inverse,
          strong: backgroundVariant?.strong,
          subtle: backgroundVariant?.subtle,
          white: backgroundVariant?.white,
        ),
        text: text.copyWith(
          main: foregroundVariant?.main,
          subtle: foregroundVariant?.subtle,
          strong: foregroundVariant?.strong,
          inverse: foregroundVariant?.inverse,
          disabled: foregroundVariant?.disabled,
          onImageStrong: foregroundVariant?.onImageStrong,
          onImageSubtle: foregroundVariant?.onImageSubtle,
        ),
        semantic: semantic.copyWith(
          info: semanticVariant?.info,
          error: semanticVariant?.error,
          success: semanticVariant?.success,
          warning: semanticVariant?.warning,
        ),
      );

  @override
  ThemeExtension<PicoColorTheme> lerp(
    covariant ThemeExtension<PicoColorTheme>? other,
    double t,
  ) {
    if (other is! PicoColorTheme) {
      return this;
    }

    return PicoColorTheme._(
      background: background.lerp(
        t: t,
        mainVariant: other.background.main,
        subtleVariant: other.background.subtle,
        strongVariant: other.background.strong,
        whiteVariant: other.background.white,
        inverseVariant: other.background.inverse,
      ),
      text: text.lerp(
        t: t,
        mainVariant: other.text.main,
        subtleVariant: other.text.subtle,
        strongVariant: other.text.strong,
        disabledVariant: other.text.disabled,
        inverseVariant: other.text.inverse,
        onImageStrongVariant: other.text.onImageStrong,
        onImageSubtleVariant: other.text.onImageSubtle,
      ),
      semantic: semantic.lerp(
        t: t,
        successVariant: other.semantic.success,
        infoVariant: other.semantic.info,
        errorVariant: other.semantic.error,
        warningVariant: other.semantic.warning,
      ),
    );
  }
}
