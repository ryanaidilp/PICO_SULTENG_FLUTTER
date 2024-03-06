import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/style/colors/pico_color_data.dart';

@immutable
class PicoColorTheme extends ThemeExtension<PicoColorTheme> {
  const PicoColorTheme._({
    required this.background,
    required this.text,
    required this.icon,
    required this.semantic,
    required this.vaccine,
    required this.outline,
  });

  factory PicoColorTheme.light() => PicoColorTheme._(
        background: PicoBackgroundColor.light(),
        text: PicoTextColor.light(),
        icon: PicoIconColor.light(),
        semantic: PicoSemanticColor.light(),
        vaccine: PicoVaccineColor.light(),
        outline: PicoOutlineColor.light(),
      );

  factory PicoColorTheme.dark() => PicoColorTheme._(
        background: PicoBackgroundColor.dark(),
        text: PicoTextColor.dark(),
        icon: PicoIconColor.dark(),
        semantic: PicoSemanticColor.dark(),
        vaccine: PicoVaccineColor.dark(),
        outline: PicoOutlineColor.dark(),
      );

  final PicoBackgroundColor background;
  final PicoTextColor text;
  final PicoIconColor icon;
  final PicoSemanticColor semantic;
  final PicoVaccineColor vaccine;
  final PicoOutlineColor outline;

  @override
  ThemeExtension<PicoColorTheme> copyWith({
    PicoBackgroundColor? backgroundVariant,
    PicoTextColor? textVariant,
    PicoIconColor? iconVariant,
    PicoSemanticColor? semanticVariant,
    PicoVaccineColor? vaccineVariant,
    PicoOutlineColor? outlineVariant,
  }) =>
      PicoColorTheme._(
        background: background.copyWith(
          card: backgroundVariant?.card,
          neutral: backgroundVariant?.neutral,
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
        outline: outline.copyWith(
          neutral: outlineVariant?.neutral,
          semantic: outlineVariant?.semantic,
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
        cardVariant: other.background.card,
        neutralVariant: other.background.neutral,
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
      outline: outline.lerp(
        t: t,
        neutralVariant: other.outline.neutral,
        semanticVariant: other.outline.semantic,
      ),
    );
  }
}
