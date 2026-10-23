import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

/// Foreground color variants for the design system.
@immutable
class const PicoForegroundColors({
  required final Color main,
  required final Color subtle,
  required final Color muted,
  required final Color disabled,
  required final Color inverse,
  required final Color success,
  required final Color warning,
  required final Color error,
  required final Color info,
  required final Color primary,
}) {
  factory light() => const PicoForegroundColors(
    main: PicoColorFoundation.foregroundMain,
    subtle: PicoColorFoundation.foregroundSubtle,
    muted: PicoColorFoundation.foregroundMuted,
    disabled: PicoColorFoundation.foregroundDisabled,
    inverse: PicoColorFoundation.foregroundInverse,
    success: PicoColorFoundation.foregroundSuccess,
    warning: PicoColorFoundation.foregroundWarning,
    error: PicoColorFoundation.foregroundError,
    info: PicoColorFoundation.foregroundInfo,
    primary: PicoColorFoundation.foregroundPrimary,
  );

  factory dark() => const PicoForegroundColors(
    main: PicoColorFoundation.foregroundMainDark,
    subtle: PicoColorFoundation.foregroundSubtleDark,
    muted: PicoColorFoundation.foregroundMutedDark,
    disabled: PicoColorFoundation.foregroundDisabledDark,
    inverse: PicoColorFoundation.foregroundInverseDark,
    success: PicoColorFoundation.foregroundSuccessDark,
    warning: PicoColorFoundation.foregroundWarningDark,
    error: PicoColorFoundation.foregroundErrorDark,
    info: PicoColorFoundation.foregroundInfoDark,
    primary: PicoColorFoundation.foregroundPrimary,
  );

  PicoForegroundColors copyWith({
    Color? main,
    Color? subtle,
    Color? muted,
    Color? disabled,
    Color? inverse,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? primary,
  }) => PicoForegroundColors(
    main: main ?? this.main,
    subtle: subtle ?? this.subtle,
    muted: muted ?? this.muted,
    disabled: disabled ?? this.disabled,
    inverse: inverse ?? this.inverse,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    info: info ?? this.info,
    primary: primary ?? this.primary,
  );

  PicoForegroundColors lerp(PicoForegroundColors? other, double t) {
    if (other == null) return this;
    return PicoForegroundColors(
      main: Color.lerp(main, other.main, t) ?? main,
      subtle: Color.lerp(subtle, other.subtle, t) ?? subtle,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
      inverse: Color.lerp(inverse, other.inverse, t) ?? inverse,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      info: Color.lerp(info, other.info, t) ?? info,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
    );
  }
}
