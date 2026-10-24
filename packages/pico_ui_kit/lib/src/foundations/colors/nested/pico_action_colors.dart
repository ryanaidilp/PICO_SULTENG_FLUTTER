import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

/// Action button state colors.
@immutable
class const PicoActionStateColors({
  required final Color active,
  required final Color hover,
  required final Color disabled,
}) {
  PicoActionStateColors copyWith({
    Color? active,
    Color? hover,
    Color? disabled,
  }) => PicoActionStateColors(
    active: active ?? this.active,
    hover: hover ?? this.hover,
    disabled: disabled ?? this.disabled,
  );

  PicoActionStateColors lerp(PicoActionStateColors? other, double t) {
    if (other == null) return this;
    return PicoActionStateColors(
      active: Color.lerp(active, other.active, t) ?? active,
      hover: Color.lerp(hover, other.hover, t) ?? hover,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
    );
  }
}

/// Action color variants for buttons and interactive elements.
@immutable
class const PicoActionColors({
  required final PicoActionStateColors primary,
  required final PicoActionStateColors secondary,
  required final PicoActionStateColors destructive,
  required final PicoActionStateColors success,
}) {
  factory light() => const PicoActionColors(
    primary: PicoActionStateColors(
      active: PicoColorFoundation.actionPrimary,
      hover: PicoColorFoundation.actionPrimaryHover,
      disabled: PicoColorFoundation.actionPrimaryDisabled,
    ),
    secondary: PicoActionStateColors(
      active: PicoColorFoundation.actionSecondary,
      hover: PicoColorFoundation.actionSecondaryHover,
      disabled: PicoColorFoundation.actionSecondaryDisabled,
    ),
    destructive: PicoActionStateColors(
      active: PicoColorFoundation.actionDestructive,
      hover: PicoColorFoundation.actionDestructiveHover,
      disabled: PicoColorFoundation.actionDestructiveDisabled,
    ),
    success: PicoActionStateColors(
      active: PicoColorFoundation.actionSuccess,
      hover: PicoColorFoundation.actionSuccessHover,
      disabled: PicoColorFoundation.actionSuccessDisabled,
    ),
  );

  /// Dark theme action colors (brand dark palette; text on filled actions is
  /// the inverse foreground, paper dark).
  factory dark() => const PicoActionColors(
    primary: PicoActionStateColors(
      active: PicoColorFoundation.actionPrimaryDark,
      hover: PicoColorFoundation.actionPrimaryHoverDark,
      disabled: PicoColorFoundation.actionPrimaryDisabledDark,
    ),
    secondary: PicoActionStateColors(
      active: PicoColorFoundation.actionSecondaryDark,
      hover: PicoColorFoundation.actionSecondaryHoverDark,
      disabled: PicoColorFoundation.actionSecondaryDisabledDark,
    ),
    destructive: PicoActionStateColors(
      active: PicoColorFoundation.actionDestructiveDark,
      hover: PicoColorFoundation.actionDestructiveHoverDark,
      disabled: PicoColorFoundation.actionDestructiveDisabledDark,
    ),
    success: PicoActionStateColors(
      active: PicoColorFoundation.actionSuccessDark,
      hover: PicoColorFoundation.actionSuccessHoverDark,
      disabled: PicoColorFoundation.actionSuccessDisabledDark,
    ),
  );

  PicoActionColors copyWith({
    PicoActionStateColors? primary,
    PicoActionStateColors? secondary,
    PicoActionStateColors? destructive,
    PicoActionStateColors? success,
  }) => PicoActionColors(
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    destructive: destructive ?? this.destructive,
    success: success ?? this.success,
  );

  PicoActionColors lerp(PicoActionColors? other, double t) {
    if (other == null) return this;
    return PicoActionColors(
      primary: primary.lerp(other.primary, t),
      secondary: secondary.lerp(other.secondary, t),
      destructive: destructive.lerp(other.destructive, t),
      success: success.lerp(other.success, t),
    );
  }
}
