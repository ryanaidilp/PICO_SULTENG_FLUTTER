import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/radius/pico_radius_token.dart';

/// Radius theme extension for the design system.
@immutable
class const PicoRadiusExtension._({
  required final double none,
  required final double xs,
  required final double sm,
  required final double md,
  required final double lg,
  required final double xl,
  required final double xl2,
  required final double full,
}) extends ThemeExtension<PicoRadiusExtension> {
  factory standard() => const PicoRadiusExtension._(
    none: PicoRadiusToken.none,
    xs: PicoRadiusToken.xs,
    sm: PicoRadiusToken.sm,
    md: PicoRadiusToken.md,
    lg: PicoRadiusToken.lg,
    xl: PicoRadiusToken.xl,
    xl2: PicoRadiusToken.xl2,
    full: PicoRadiusToken.full,
  );

  /// Presets read this extension's values, so `copyWith(md: 20)` reaches
  /// every `radius.border.md` reader.
  PicoBorderRadiusPresets get border => PicoBorderRadiusPresets._(this);
  PicoRadiusPresets get circular => PicoRadiusPresets._(this);

  @override
  ThemeExtension<PicoRadiusExtension> copyWith({
    double? none,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xl2,
    double? full,
    @Deprecated('Ignored: presets derive from the radius values.')
    PicoBorderRadiusPresets? border,
    @Deprecated('Ignored: presets derive from the radius values.')
    PicoRadiusPresets? circular,
  }) => PicoRadiusExtension._(
    none: none ?? this.none,
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xl2: xl2 ?? this.xl2,
    full: full ?? this.full,
  );

  @override
  ThemeExtension<PicoRadiusExtension> lerp(
    covariant ThemeExtension<PicoRadiusExtension>? other,
    double t,
  ) {
    if (other is! PicoRadiusExtension) return this;
    double l(double a, double b, double t) => a + (b - a) * t;
    return PicoRadiusExtension._(
      none: l(none, other.none, t),
      xs: l(xs, other.xs, t),
      sm: l(sm, other.sm, t),
      md: l(md, other.md, t),
      lg: l(lg, other.lg, t),
      xl: l(xl, other.xl, t),
      xl2: l(xl2, other.xl2, t),
      full: l(full, other.full, t),
    );
  }
}

@immutable
class const PicoBorderRadiusPresets._(final PicoRadiusExtension _radius) {
  BorderRadius get none => BorderRadius.circular(_radius.none);
  BorderRadius get xs => BorderRadius.circular(_radius.xs);
  BorderRadius get sm => BorderRadius.circular(_radius.sm);
  BorderRadius get md => BorderRadius.circular(_radius.md);
  BorderRadius get lg => BorderRadius.circular(_radius.lg);
  BorderRadius get xl => BorderRadius.circular(_radius.xl);
  BorderRadius get xl2 => BorderRadius.circular(_radius.xl2);
  BorderRadius get full => BorderRadius.circular(_radius.full);
}

@immutable
class const PicoRadiusPresets._(final PicoRadiusExtension _radius) {
  Radius get none => Radius.circular(_radius.none);
  Radius get xs => Radius.circular(_radius.xs);
  Radius get sm => Radius.circular(_radius.sm);
  Radius get md => Radius.circular(_radius.md);
  Radius get lg => Radius.circular(_radius.lg);
  Radius get xl => Radius.circular(_radius.xl);
  Radius get xl2 => Radius.circular(_radius.xl2);
  Radius get full => Radius.circular(_radius.full);
}
