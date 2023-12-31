import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/style/colors/pico_color_data.dart';
import 'package:pico_ui_kit/src/style/pico_colors.dart';

@immutable
class PicoColorTheme extends ThemeExtension<PicoColorTheme> {
  const PicoColorTheme._({
    required this.background,
    required this.text,
    required this.icon,
    required this.semantic,
    required this.vaccine,
  });

  factory PicoColorTheme.light() => PicoColorTheme._(
        background: PicoBackgroundNeutralColor(
          main: PicoColors.bgMain,
          subtle: PicoColors.bgSubtle,
          strong: PicoColors.bgStrong,
          white: PicoColors.bgWhite,
          inverse: PicoColors.bgInverse,
        ),
        text: PicoTextColor(
          neutral: PicoForegroundNeutralColor(
            main: PicoColors.textMain,
            subtle: PicoColors.textSubtle,
            strong: PicoColors.textStrong,
            disabled: PicoColors.textDisabled,
            inverse: PicoColors.textInverse,
            onImageStrong: PicoColors.textOnImageStrong,
            onImageSubtle: PicoColors.textOnImageSubtle,
          ),
          semantic: PicoForegroundSemanticColor(
            info: PicoColors.info.shade500,
            error: PicoColors.error.shade600,
            success: PicoColors.success.shade600,
            warning: PicoColors.warning.shade600,
            primary: PicoColors.primary.shade500,
            secondary: PicoColors.secondary.shade600,
            tertiary: PicoColors.tertiary.shade500,
          ),
        ),
        icon: PicoIconColor(
          neutral: PicoForegroundNeutralColor(
            main: PicoColors.textMain,
            subtle: PicoColors.textSubtle,
            strong: PicoColors.textStrong,
            disabled: PicoColors.textDisabled,
            inverse: PicoColors.textInverse,
            onImageStrong: PicoColors.textOnImageStrong,
            onImageSubtle: PicoColors.textOnImageSubtle,
          ),
          semantic: PicoForegroundSemanticColor(
            info: PicoColors.info.shade500,
            error: PicoColors.error.shade600,
            success: PicoColors.success.shade600,
            warning: PicoColors.warning.shade600,
            primary: PicoColors.primary.shade500,
            secondary: PicoColors.secondary.shade600,
            tertiary: PicoColors.tertiary.shade500,
          ),
        ),
        semantic: const PicoSemanticColor(
          info: PicoColors.info,
          error: PicoColors.error,
          success: PicoColors.success,
          warning: PicoColors.warning,
          primary: PicoColors.primary,
          secondary: PicoColors.secondary,
          tertiary: PicoColors.tertiary,
        ),
        vaccine: PicoVaccineColor(
          public: PicoColors.vaccinePublic,
          elderly: PicoColors.vaccineElderly,
          teenager: PicoColors.vaccineTeenager,
          main: PicoColors.vaccineAll,
          healthWorker: PicoColors.vaccineHealthWorker,
          publicWorker: PicoColors.vaccinePublicWorker,
        ),
      );

  factory PicoColorTheme.dark() => PicoColorTheme._(
        background: PicoBackgroundNeutralColor(
          main: PicoColors.bgMainDark,
          subtle: PicoColors.bgSubtleDark,
          strong: PicoColors.bgStrongDark,
          white: PicoColors.bgWhiteDark,
          inverse: PicoColors.bgInverseDark,
        ),
        text: PicoTextColor(
          neutral: PicoForegroundNeutralColor(
            main: PicoColors.textMainDark,
            subtle: PicoColors.textSubtleDark,
            strong: PicoColors.textStrongDark,
            disabled: PicoColors.textDisabledDark,
            inverse: PicoColors.textInverseDark,
            onImageStrong: PicoColors.textOnImageStrongDark,
            onImageSubtle: PicoColors.textOnImageSubtleDark,
          ),
          semantic: PicoForegroundSemanticColor(
            info: PicoColors.info.shade300,
            error: PicoColors.error.shade400,
            success: PicoColors.success.shade400,
            warning: PicoColors.warning.shade300,
            primary: PicoColors.primary.shade400,
            secondary: PicoColors.secondary.shade400,
            tertiary: PicoColors.tertiary.shade400,
          ),
        ),
        icon: PicoIconColor(
          neutral: PicoForegroundNeutralColor(
            main: PicoColors.textMainDark,
            subtle: PicoColors.textSubtleDark,
            strong: PicoColors.textStrongDark,
            disabled: PicoColors.textDisabledDark,
            inverse: PicoColors.textInverseDark,
            onImageStrong: PicoColors.textOnImageStrongDark,
            onImageSubtle: PicoColors.textOnImageSubtleDark,
          ),
          semantic: PicoForegroundSemanticColor(
            info: PicoColors.info.shade300,
            error: PicoColors.error.shade400,
            success: PicoColors.success.shade400,
            warning: PicoColors.warning.shade300,
            primary: PicoColors.primary.shade400,
            secondary: PicoColors.secondary.shade400,
            tertiary: PicoColors.tertiary.shade400,
          ),
        ),
        semantic: const PicoSemanticColor(
          info: PicoColors.info,
          error: PicoColors.error,
          success: PicoColors.success,
          warning: PicoColors.warning,
          primary: PicoColors.primary,
          secondary: PicoColors.secondary,
          tertiary: PicoColors.tertiary,
        ),
        vaccine: PicoVaccineColor(
          public: PicoColors.vaccinePublicDark,
          elderly: PicoColors.vaccineElderlyDark,
          teenager: PicoColors.vaccineTeenagerDark,
          main: PicoColors.vaccineAllDark,
          healthWorker: PicoColors.vaccineHealthWorkerDark,
          publicWorker: PicoColors.vaccinePublicWorkerDark,
        ),
      );

  final PicoBackgroundNeutralColor background;
  final PicoTextColor text;
  final PicoIconColor icon;
  final PicoSemanticColor semantic;
  final PicoVaccineColor vaccine;

  @override
  ThemeExtension<PicoColorTheme> copyWith({
    PicoBackgroundNeutralColor? backgroundVariant,
    PicoTextColor? textVariant,
    PicoIconColor? iconVariant,
    PicoSemanticColor? semanticVariant,
    PicoVaccineColor? vaccineVariant,
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
          neutral: textVariant?.neutral,
          semantic: textVariant?.semantic,
        ),
        icon: icon.copyWith(
          neutral: iconVariant?.neutral,
          semantic: iconVariant?.semantic,
        ),
        semantic: semantic.copyWith(
          info: semanticVariant?.info,
          error: semanticVariant?.error,
          success: semanticVariant?.success,
          warning: semanticVariant?.warning,
        ),
        vaccine: vaccine.copyWith(
          main: vaccineVariant?.main,
          public: vaccineVariant?.public,
          elderly: vaccineVariant?.elderly,
          teenager: vaccineVariant?.teenager,
          healthWorker: vaccineVariant?.healthWorker,
          publicWorker: vaccineVariant?.publicWorker,
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
        neutral: other.text.neutral,
        semantic: other.text.semantic,
      ),
      icon: icon.lerp(
        t: t,
        neutral: other.icon.neutral,
        semantic: other.icon.semantic,
      ),
      semantic: semantic.lerp(
        t: t,
        successVariant: other.semantic.success,
        infoVariant: other.semantic.info,
        errorVariant: other.semantic.error,
        warningVariant: other.semantic.warning,
        primaryVariant: other.semantic.primary,
        secondaryVariant: other.semantic.secondary,
        tertiaryVariant: other.semantic.tertiary,
      ),
      vaccine: vaccine.lerp(
        t: t,
        mainVariant: other.vaccine.main,
        publicVariant: other.vaccine.public,
        elderlyVariant: other.vaccine.elderly,
        teenagerVariant: other.vaccine.teenager,
        healthWorkerVariant: other.vaccine.healthWorker,
        publicWorkerVariant: other.vaccine.publicWorker,
      ),
    );
  }
}
