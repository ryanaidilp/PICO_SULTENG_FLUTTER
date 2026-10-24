import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_token.dart';

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

  /// Dark theme action colors. `primary.active` stays at primary600 (6.3:1
  /// on white); the other families step one tier darker for white-text
  /// contrast, hover brightens, disabled sinks toward the background.
  factory dark() => const PicoActionColors(
    primary: PicoActionStateColors(
      active: PicoColorToken.primary600,
      hover: PicoColorToken.primary500,
      disabled: PicoColorToken.primary800,
    ),
    secondary: PicoActionStateColors(
      active: PicoColorToken.secondary700,
      hover: PicoColorToken.secondary600,
      disabled: PicoColorToken.secondary900,
    ),
    destructive: PicoActionStateColors(
      active: PicoColorToken.error700,
      hover: PicoColorToken.error600,
      disabled: PicoColorToken.error900,
    ),
    success: PicoActionStateColors(
      active: PicoColorToken.success700,
      hover: PicoColorToken.success600,
      disabled: PicoColorToken.success900,
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
