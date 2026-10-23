import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/shadows/pico_shadow_foundation.dart';

/// Shadow theme extension for the design system.
@immutable
class const PicoShadowExtension._({
  required final List<BoxShadow> none,
  required final List<BoxShadow> xs,
  required final List<BoxShadow> sm,
  required final List<BoxShadow> md,
  required final List<BoxShadow> lg,
  required final List<BoxShadow> xl,
  required final List<BoxShadow> xl2,
}) extends ThemeExtension<PicoShadowExtension> {
  factory light() => const PicoShadowExtension._(
    none: PicoShadowFoundation.none,
    xs: PicoShadowFoundation.xs,
    sm: PicoShadowFoundation.sm,
    md: PicoShadowFoundation.md,
    lg: PicoShadowFoundation.lg,
    xl: PicoShadowFoundation.xl,
    xl2: PicoShadowFoundation.xl2,
  );

  factory dark() => const PicoShadowExtension._(
    none: PicoShadowFoundation.none,
    xs: PicoShadowFoundation.xsDark,
    sm: PicoShadowFoundation.smDark,
    md: PicoShadowFoundation.mdDark,
    lg: PicoShadowFoundation.lgDark,
    xl: PicoShadowFoundation.xlDark,
    xl2: PicoShadowFoundation.xl2Dark,
  );

  @override
  ThemeExtension<PicoShadowExtension> copyWith({
    List<BoxShadow>? none,
    List<BoxShadow>? xs,
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? xl,
    List<BoxShadow>? xl2,
  }) => PicoShadowExtension._(
    none: none ?? this.none,
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xl2: xl2 ?? this.xl2,
  );

  @override
  ThemeExtension<PicoShadowExtension> lerp(
    covariant ThemeExtension<PicoShadowExtension>? other,
    double t,
  ) {
    if (other is! PicoShadowExtension) return this;
    return PicoShadowExtension._(
      none: BoxShadow.lerpList(none, other.none, t) ?? none,
      xs: BoxShadow.lerpList(xs, other.xs, t) ?? xs,
      sm: BoxShadow.lerpList(sm, other.sm, t) ?? sm,
      md: BoxShadow.lerpList(md, other.md, t) ?? md,
      lg: BoxShadow.lerpList(lg, other.lg, t) ?? lg,
      xl: BoxShadow.lerpList(xl, other.xl, t) ?? xl,
      xl2: BoxShadow.lerpList(xl2, other.xl2, t) ?? xl2,
    );
  }
}
