import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_shadow_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';

/// Card variant types with style mappings.
enum PicoCardVariant() {
  /// Elevated card with shadow.
  elevated,

  /// Filled card with background color.
  filled,

  /// Outlined card with border.
  outlined;

  /// Returns the background color for this variant.
  Color backgroundColor(PicoColorExtension colors) => switch (this) {
    PicoCardVariant.elevated => colors.background.card,
    PicoCardVariant.filled => colors.background.cardSecondary,
    PicoCardVariant.outlined => colors.background.card,
  };

  /// Returns the box shadow for this variant.
  List<BoxShadow>? boxShadow(PicoShadowExtension shadow) => switch (this) {
    PicoCardVariant.elevated => shadow.sm,
    PicoCardVariant.filled => null,
    PicoCardVariant.outlined => null,
  };

  /// Returns the border for this variant.
  Border? border(PicoColorExtension colors) => switch (this) {
    PicoCardVariant.elevated => null,
    PicoCardVariant.filled => null,
    PicoCardVariant.outlined => Border.all(color: colors.outline.main),
  };

  /// Builds the complete BoxDecoration for this variant.
  BoxDecoration decoration(
    PicoColorExtension colors,
    PicoShadowExtension shadow,
    BorderRadiusGeometry borderRadius,
  ) => BoxDecoration(
    color: backgroundColor(colors),
    borderRadius: borderRadius,
    boxShadow: boxShadow(shadow),
    border: border(colors),
  );

  /// Returns true if this variant has a shadow.
  bool get hasElevation => this == PicoCardVariant.elevated;

  /// Returns true if this variant has a border.
  bool get hasBorder => this == PicoCardVariant.outlined;
}

/// Card size presets with dimension mappings.
enum PicoCardSize() {
  /// Small card with minimal padding.
  sm,

  /// Medium card with standard padding.
  md,

  /// Large card with generous padding.
  lg;

  /// Returns the default padding for this size.
  EdgeInsetsGeometry padding(PicoSpacingExtension spacing) => switch (this) {
    PicoCardSize.sm => spacing.insets.allSm,
    PicoCardSize.md => spacing.insets.allMd,
    PicoCardSize.lg => spacing.insets.allLg,
  };

  /// Returns the border radius for this size.
  BorderRadius borderRadius(PicoRadiusExtension radius) => switch (this) {
    PicoCardSize.sm => radius.border.sm,
    PicoCardSize.md => radius.border.md,
    PicoCardSize.lg => radius.border.lg,
  };
}
