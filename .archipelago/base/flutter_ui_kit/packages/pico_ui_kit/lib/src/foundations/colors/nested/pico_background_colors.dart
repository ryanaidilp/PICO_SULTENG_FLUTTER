import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

/// Background color variants for the design system.
@immutable
class const PicoBackgroundColors({
  required final Color main,
  required final Color subtle,
  required final Color strong,
  required final Color inverse,
  required final Color card,
  required final Color cardSecondary,
  required final Color success,
  required final Color warning,
  required final Color error,
  required final Color info,
}) {
  factory light() => const PicoBackgroundColors(
    main: PicoColorFoundation.bgMain,
    subtle: PicoColorFoundation.bgSubtle,
    strong: PicoColorFoundation.bgStrong,
    inverse: PicoColorFoundation.bgInverse,
    card: PicoColorFoundation.bgCard,
    cardSecondary: PicoColorFoundation.bgCardSecondary,
    success: PicoColorFoundation.successBg,
    warning: PicoColorFoundation.warningBg,
    error: PicoColorFoundation.errorBg,
    info: PicoColorFoundation.infoBg,
  );

  factory dark() => const PicoBackgroundColors(
    main: PicoColorFoundation.bgMainDark,
    subtle: PicoColorFoundation.bgSubtleDark,
    strong: PicoColorFoundation.bgStrongDark,
    inverse: PicoColorFoundation.bgInverseDark,
    card: PicoColorFoundation.bgCardDark,
    cardSecondary: PicoColorFoundation.bgCardSecondaryDark,
    success: PicoColorFoundation.successBgDark,
    warning: PicoColorFoundation.warningBgDark,
    error: PicoColorFoundation.errorBgDark,
    info: PicoColorFoundation.infoBgDark,
  );

  PicoBackgroundColors copyWith({
    Color? main,
    Color? subtle,
    Color? strong,
    Color? inverse,
    Color? card,
    Color? cardSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) => PicoBackgroundColors(
    main: main ?? this.main,
    subtle: subtle ?? this.subtle,
    strong: strong ?? this.strong,
    inverse: inverse ?? this.inverse,
    card: card ?? this.card,
    cardSecondary: cardSecondary ?? this.cardSecondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    info: info ?? this.info,
  );

  PicoBackgroundColors lerp(PicoBackgroundColors? other, double t) {
    if (other == null) return this;
    return PicoBackgroundColors(
      main: Color.lerp(main, other.main, t) ?? main,
      subtle: Color.lerp(subtle, other.subtle, t) ?? subtle,
      strong: Color.lerp(strong, other.strong, t) ?? strong,
      inverse: Color.lerp(inverse, other.inverse, t) ?? inverse,
      card: Color.lerp(card, other.card, t) ?? card,
      cardSecondary:
          Color.lerp(cardSecondary, other.cardSecondary, t) ?? cardSecondary,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}
