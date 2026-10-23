import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

/// Outline/border color variants for the design system.
@immutable
class const PicoOutlineColors({
  required final Color main,
  required final Color strong,
  required final Color subtle,
  required final Color focus,
}) {
  factory light() => const PicoOutlineColors(
    main: PicoColorFoundation.outlineMain,
    strong: PicoColorFoundation.outlineStrong,
    subtle: PicoColorFoundation.outlineSubtle,
    focus: PicoColorFoundation.outlineFocus,
  );

  factory dark() => const PicoOutlineColors(
    main: PicoColorFoundation.outlineMainDark,
    strong: PicoColorFoundation.outlineStrongDark,
    subtle: PicoColorFoundation.outlineSubtleDark,
    focus: PicoColorFoundation.outlineFocusDark,
  );

  PicoOutlineColors copyWith({
    Color? main,
    Color? strong,
    Color? subtle,
    Color? focus,
  }) => PicoOutlineColors(
    main: main ?? this.main,
    strong: strong ?? this.strong,
    subtle: subtle ?? this.subtle,
    focus: focus ?? this.focus,
  );

  PicoOutlineColors lerp(PicoOutlineColors? other, double t) {
    if (other == null) return this;
    return PicoOutlineColors(
      main: Color.lerp(main, other.main, t) ?? main,
      strong: Color.lerp(strong, other.strong, t) ?? strong,
      subtle: Color.lerp(subtle, other.subtle, t) ?? subtle,
      focus: Color.lerp(focus, other.focus, t) ?? focus,
    );
  }
}
