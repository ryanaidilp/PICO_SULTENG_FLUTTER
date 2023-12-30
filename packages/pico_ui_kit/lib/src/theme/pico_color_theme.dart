import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/style/colors/pico_color_data.dart';
import 'package:pico_ui_kit/src/style/pico_colors.dart';

@immutable
class PicoColorTheme extends ThemeExtension<PicoColorTheme> {
  const PicoColorTheme._({
    required this.background,
    required this.text,
    required this.semantic,
    required this.vaccine,
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
        vaccine: PicoVaccineColor(
          public: PicoColors.vaccinePublicDark,
          elderly: PicoColors.vaccineElderlyDark,
          teenager: PicoColors.vaccineTeenagerDark,
          main: PicoColors.vaccineAllDark,
          healthWorker: PicoColors.vaccineHealthWorkerDark,
          publicWorker: PicoColors.vaccinePublicWorkerDark,
        ),
      );

  final PicoBackgroundNeutral background;
  final PicoForegroundNeutral text;
  final PicoSemanticColor semantic;
  final PicoVaccineColor vaccine;

  @override
  ThemeExtension<PicoColorTheme> copyWith({
    PicoBackgroundNeutral? backgroundVariant,
    PicoTextNeutral? foregroundVariant,
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
