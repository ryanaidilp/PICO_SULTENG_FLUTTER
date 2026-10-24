import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_font_family.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_typography_foundation.dart';

/// Typography theme extension for the design system.
@immutable
class const PicoTypographyExtension._({
  required final PicoDisplayTypography display,
  required final PicoHeadingTypography heading,
  required final PicoBodyTypography body,
  required final PicoLabelTypography label,
  required final PicoButtonTypography button,
  required final PicoCodeTypography code,
}) extends ThemeExtension<PicoTypographyExtension> {
  /// [sizes] overrides the type scale by key (`h1`, `body`, ...), see
  /// [PicoTypographyFoundation].
  factory standard({
    PicoFontFamily? fontFamily,
    Map<String, double> sizes = const {},
  }) {
    final typography = PicoTypographyFoundation(
      fontFamily: fontFamily ?? const PicoFontFamily(),
      sizes: sizes,
    );
    return PicoTypographyExtension._(
      display: PicoDisplayTypography._(
        large: typography.display1,
        medium: typography.display2,
        small: typography.display3,
      ),
      heading: PicoHeadingTypography._(
        h1: typography.h1,
        h2: typography.h2,
        h3: typography.h3,
        h4: typography.h4,
        h5: typography.h5,
        h6: typography.h6,
      ),
      body: PicoBodyTypography._(
        large: typography.bodyLarge,
        regular: typography.body,
        small: typography.bodySmall,
        largeMedium: typography.bodyLargeMedium,
        medium: typography.bodyMedium,
        smallMedium: typography.bodySmallMedium,
      ),
      label: PicoLabelTypography._(
        caption: typography.caption,
        captionMedium: typography.captionMedium,
        overline: typography.overline,
      ),
      button: PicoButtonTypography._(
        large: typography.buttonLarge,
        regular: typography.button,
        small: typography.buttonSmall,
      ),
      code: PicoCodeTypography._(
        regular: typography.code,
        small: typography.codeSmall,
      ),
    );
  }

  @override
  ThemeExtension<PicoTypographyExtension> copyWith({
    PicoDisplayTypography? display,
    PicoHeadingTypography? heading,
    PicoBodyTypography? body,
    PicoLabelTypography? label,
    PicoButtonTypography? button,
    PicoCodeTypography? code,
  }) => PicoTypographyExtension._(
    display: display ?? this.display,
    heading: heading ?? this.heading,
    body: body ?? this.body,
    label: label ?? this.label,
    button: button ?? this.button,
    code: code ?? this.code,
  );

  @override
  ThemeExtension<PicoTypographyExtension> lerp(
    covariant ThemeExtension<PicoTypographyExtension>? other,
    double t,
  ) {
    if (other is! PicoTypographyExtension) return this;
    return PicoTypographyExtension._(
      display: display.lerp(other.display, t),
      heading: heading.lerp(other.heading, t),
      body: body.lerp(other.body, t),
      label: label.lerp(other.label, t),
      button: button.lerp(other.button, t),
      code: code.lerp(other.code, t),
    );
  }
}

@immutable
class const PicoDisplayTypography._({
  required final TextStyle large,
  required final TextStyle medium,
  required final TextStyle small,
}) {
  PicoDisplayTypography lerp(PicoDisplayTypography? other, double t) {
    if (other == null) return this;
    return PicoDisplayTypography._(
      large: TextStyle.lerp(large, other.large, t) ?? large,
      medium: TextStyle.lerp(medium, other.medium, t) ?? medium,
      small: TextStyle.lerp(small, other.small, t) ?? small,
    );
  }
}

@immutable
class const PicoHeadingTypography._({
  required final TextStyle h1,
  required final TextStyle h2,
  required final TextStyle h3,
  required final TextStyle h4,
  required final TextStyle h5,
  required final TextStyle h6,
}) {
  PicoHeadingTypography lerp(PicoHeadingTypography? other, double t) {
    if (other == null) return this;
    return PicoHeadingTypography._(
      h1: TextStyle.lerp(h1, other.h1, t) ?? h1,
      h2: TextStyle.lerp(h2, other.h2, t) ?? h2,
      h3: TextStyle.lerp(h3, other.h3, t) ?? h3,
      h4: TextStyle.lerp(h4, other.h4, t) ?? h4,
      h5: TextStyle.lerp(h5, other.h5, t) ?? h5,
      h6: TextStyle.lerp(h6, other.h6, t) ?? h6,
    );
  }
}

@immutable
class const PicoBodyTypography._({
  required final TextStyle large,
  required final TextStyle regular,
  required final TextStyle small,
  required final TextStyle largeMedium,
  required final TextStyle medium,
  required final TextStyle smallMedium,
}) {
  PicoBodyTypography lerp(PicoBodyTypography? other, double t) {
    if (other == null) return this;
    return PicoBodyTypography._(
      large: TextStyle.lerp(large, other.large, t) ?? large,
      regular: TextStyle.lerp(regular, other.regular, t) ?? regular,
      small: TextStyle.lerp(small, other.small, t) ?? small,
      largeMedium:
          TextStyle.lerp(largeMedium, other.largeMedium, t) ?? largeMedium,
      medium: TextStyle.lerp(medium, other.medium, t) ?? medium,
      smallMedium:
          TextStyle.lerp(smallMedium, other.smallMedium, t) ?? smallMedium,
    );
  }
}

@immutable
class const PicoLabelTypography._({
  required final TextStyle caption,
  required final TextStyle captionMedium,
  required final TextStyle overline,
}) {
  PicoLabelTypography lerp(PicoLabelTypography? other, double t) {
    if (other == null) return this;
    return PicoLabelTypography._(
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      captionMedium:
          TextStyle.lerp(captionMedium, other.captionMedium, t) ??
          captionMedium,
      overline: TextStyle.lerp(overline, other.overline, t) ?? overline,
    );
  }
}

@immutable
class const PicoButtonTypography._({
  required final TextStyle large,
  required final TextStyle regular,
  required final TextStyle small,
}) {
  PicoButtonTypography lerp(PicoButtonTypography? other, double t) {
    if (other == null) return this;
    return PicoButtonTypography._(
      large: TextStyle.lerp(large, other.large, t) ?? large,
      regular: TextStyle.lerp(regular, other.regular, t) ?? regular,
      small: TextStyle.lerp(small, other.small, t) ?? small,
    );
  }
}

@immutable
class const PicoCodeTypography._({
  required final TextStyle regular,
  required final TextStyle small,
}) {
  PicoCodeTypography lerp(PicoCodeTypography? other, double t) {
    if (other == null) return this;
    return PicoCodeTypography._(
      regular: TextStyle.lerp(regular, other.regular, t) ?? regular,
      small: TextStyle.lerp(small, other.small, t) ?? small,
    );
  }
}
