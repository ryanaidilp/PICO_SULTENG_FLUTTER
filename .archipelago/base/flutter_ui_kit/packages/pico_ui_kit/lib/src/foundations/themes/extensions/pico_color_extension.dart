import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_action_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_background_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_foreground_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_outline_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

/// Color theme extension for the design system.
@immutable
class const PicoColorExtension._({
  required final PicoForegroundColors foreground,
  required final PicoBackgroundColors background,
  required final PicoActionColors action,
  required final PicoOutlineColors outline,
  required final Color overlay,
}) extends ThemeExtension<PicoColorExtension> {
  factory light() => PicoColorExtension._(
    foreground: PicoForegroundColors.light(),
    background: PicoBackgroundColors.light(),
    action: PicoActionColors.light(),
    outline: PicoOutlineColors.light(),
    overlay: PicoColorFoundation.overlay,
  );

  factory dark() => PicoColorExtension._(
    foreground: PicoForegroundColors.dark(),
    background: PicoBackgroundColors.dark(),
    action: PicoActionColors.dark(),
    outline: PicoOutlineColors.dark(),
    overlay: PicoColorFoundation.overlayDark,
  );

  @override
  ThemeExtension<PicoColorExtension> copyWith({
    PicoForegroundColors? foreground,
    PicoBackgroundColors? background,
    PicoActionColors? action,
    PicoOutlineColors? outline,
    Color? overlay,
  }) => PicoColorExtension._(
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    action: action ?? this.action,
    outline: outline ?? this.outline,
    overlay: overlay ?? this.overlay,
  );

  @override
  ThemeExtension<PicoColorExtension> lerp(
    covariant ThemeExtension<PicoColorExtension>? other,
    double t,
  ) {
    if (other is! PicoColorExtension) return this;
    return PicoColorExtension._(
      foreground: foreground.lerp(other.foreground, t),
      background: background.lerp(other.background, t),
      action: action.lerp(other.action, t),
      outline: outline.lerp(other.outline, t),
      overlay: Color.lerp(overlay, other.overlay, t) ?? overlay,
    );
  }
}
