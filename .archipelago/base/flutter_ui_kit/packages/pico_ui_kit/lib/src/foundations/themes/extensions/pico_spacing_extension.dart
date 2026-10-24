import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/spacing/pico_spacing_foundation.dart';
import 'package:pico_ui_kit/src/foundations/spacing/pico_spacing_token.dart';

/// Spacing theme extension for the design system.
@immutable
class const PicoSpacingExtension._({
  required final double none,
  required final double xxs,
  required final double xs,
  required final double sm,
  required final double md,
  required final double lg,
  required final double xl,
  required final double xl2,
  required final double xl3,
  required final double xl4,
  required final double xl5,
  required final double xl6,
  required final PicoSpacingInsets insets,
}) extends ThemeExtension<PicoSpacingExtension> {
  factory standard() => const PicoSpacingExtension._(
    none: PicoSpacingToken.none,
    xxs: PicoSpacingToken.xxs,
    xs: PicoSpacingToken.xs,
    sm: PicoSpacingToken.sm,
    md: PicoSpacingToken.md,
    lg: PicoSpacingToken.lg,
    xl: PicoSpacingToken.xl,
    xl2: PicoSpacingToken.xl2,
    xl3: PicoSpacingToken.xl3,
    xl4: PicoSpacingToken.xl4,
    xl5: PicoSpacingToken.xl5,
    xl6: PicoSpacingToken.xl6,
    insets: PicoSpacingInsets._(),
  );

  @override
  ThemeExtension<PicoSpacingExtension> copyWith({
    double? none,
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xl2,
    double? xl3,
    double? xl4,
    double? xl5,
    double? xl6,
    PicoSpacingInsets? insets,
  }) => PicoSpacingExtension._(
    none: none ?? this.none,
    xxs: xxs ?? this.xxs,
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xl2: xl2 ?? this.xl2,
    xl3: xl3 ?? this.xl3,
    xl4: xl4 ?? this.xl4,
    xl5: xl5 ?? this.xl5,
    xl6: xl6 ?? this.xl6,
    insets: insets ?? this.insets,
  );

  @override
  ThemeExtension<PicoSpacingExtension> lerp(
    covariant ThemeExtension<PicoSpacingExtension>? other,
    double t,
  ) {
    if (other is! PicoSpacingExtension) return this;
    double l(double a, double b, double t) => a + (b - a) * t;
    return PicoSpacingExtension._(
      none: l(none, other.none, t),
      xxs: l(xxs, other.xxs, t),
      xs: l(xs, other.xs, t),
      sm: l(sm, other.sm, t),
      md: l(md, other.md, t),
      lg: l(lg, other.lg, t),
      xl: l(xl, other.xl, t),
      xl2: l(xl2, other.xl2, t),
      xl3: l(xl3, other.xl3, t),
      xl4: l(xl4, other.xl4, t),
      xl5: l(xl5, other.xl5, t),
      xl6: l(xl6, other.xl6, t),
      insets: insets,
    );
  }
}

/// Pre-configured EdgeInsets using spacing tokens.
@immutable
class const PicoSpacingInsets._() {
  EdgeInsets get allNone => PicoSpacingFoundation.allNone;
  EdgeInsets get allXxs => PicoSpacingFoundation.allXxs;
  EdgeInsets get allXs => PicoSpacingFoundation.allXs;
  EdgeInsets get allSm => PicoSpacingFoundation.allSm;
  EdgeInsets get allMd => PicoSpacingFoundation.allMd;
  EdgeInsets get allLg => PicoSpacingFoundation.allLg;
  EdgeInsets get allXl => PicoSpacingFoundation.allXl;
  EdgeInsets get allXl2 => PicoSpacingFoundation.allXl2;
  EdgeInsets get allXl3 => PicoSpacingFoundation.allXl3;
  EdgeInsets get allXl4 => PicoSpacingFoundation.allXl4;

  EdgeInsets get horizontalXxs => PicoSpacingFoundation.horizontalXxs;
  EdgeInsets get horizontalXs => PicoSpacingFoundation.horizontalXs;
  EdgeInsets get horizontalSm => PicoSpacingFoundation.horizontalSm;
  EdgeInsets get horizontalMd => PicoSpacingFoundation.horizontalMd;
  EdgeInsets get horizontalLg => PicoSpacingFoundation.horizontalLg;
  EdgeInsets get horizontalXl => PicoSpacingFoundation.horizontalXl;
  EdgeInsets get horizontalXl2 => PicoSpacingFoundation.horizontalXl2;
  EdgeInsets get horizontalXl3 => PicoSpacingFoundation.horizontalXl3;
  EdgeInsets get horizontalXl4 => PicoSpacingFoundation.horizontalXl4;

  EdgeInsets get verticalXxs => PicoSpacingFoundation.verticalXxs;
  EdgeInsets get verticalXs => PicoSpacingFoundation.verticalXs;
  EdgeInsets get verticalSm => PicoSpacingFoundation.verticalSm;
  EdgeInsets get verticalMd => PicoSpacingFoundation.verticalMd;
  EdgeInsets get verticalLg => PicoSpacingFoundation.verticalLg;
  EdgeInsets get verticalXl => PicoSpacingFoundation.verticalXl;
  EdgeInsets get verticalXl2 => PicoSpacingFoundation.verticalXl2;
  EdgeInsets get verticalXl3 => PicoSpacingFoundation.verticalXl3;
  EdgeInsets get verticalXl4 => PicoSpacingFoundation.verticalXl4;
}
