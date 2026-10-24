import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';

/// Input field variant types with style mappings.
enum PicoTextFieldVariant() {
  /// Bordered input with full border.
  bordered,

  /// Underlined input with bottom border only.
  underlined,

  /// Ghost input with no visible border in any state.
  ghost;

  /// Returns the border radius for this variant.
  BorderRadius borderRadius(PicoRadiusExtension radius) => switch (this) {
    PicoTextFieldVariant.bordered => radius.border.md,
    PicoTextFieldVariant.underlined => BorderRadius.zero,
    PicoTextFieldVariant.ghost => radius.border.sm,
  };

  /// Returns the input border based on state.
  InputBorder resolveBorder({
    required PicoRadiusExtension radius,
    required Color color,
    required bool isFocused,
  }) {
    final borderRadius = this.borderRadius(radius);

    return switch (this) {
      PicoTextFieldVariant.bordered => OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color),
      ),
      PicoTextFieldVariant.underlined => UnderlineInputBorder(
        borderSide: BorderSide(color: color),
      ),
      PicoTextFieldVariant.ghost => OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
    };
  }

  /// Whether this variant should show fill color only when focused.
  bool get showFillOnFocusOnly => this == PicoTextFieldVariant.ghost;
}

/// Input field size presets with dimension mappings.
enum PicoTextFieldSize({
  /// The height of the input field.
  required final double height,
}) {
  /// Small input (40px height).
  sm(height: 40),

  /// Medium input (48px height).
  md(height: 48),

  /// Large input (56px height).
  lg(height: 56);

  /// Returns the content padding for this size.
  EdgeInsetsGeometry contentPadding(PicoSpacingExtension spacing) =>
      switch (this) {
        PicoTextFieldSize.sm => EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        PicoTextFieldSize.md => EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        PicoTextFieldSize.lg => EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.md,
        ),
      };

  /// Returns the text style for this size.
  TextStyle textStyle(PicoTypographyExtension typography) => switch (this) {
    PicoTextFieldSize.sm => typography.body.small,
    PicoTextFieldSize.md => typography.body.regular,
    PicoTextFieldSize.lg => typography.body.large,
  };

  /// Returns the icon size for this text field size.
  double get iconSize => switch (this) {
    PicoTextFieldSize.sm => 18,
    PicoTextFieldSize.md => 20,
    PicoTextFieldSize.lg => 24,
  };
}

/// Input field state for resolving colors.
enum PicoTextFieldState() {
  /// Normal/idle state.
  normal,

  /// Focused state.
  focused,

  /// Error state.
  error,

  /// Disabled state.
  disabled;

  /// Resolves the border color for this state.
  Color borderColor(PicoColorExtension colors) => switch (this) {
    PicoTextFieldState.normal => colors.outline.main,
    PicoTextFieldState.focused => colors.action.primary.active,
    PicoTextFieldState.error => colors.action.destructive.active,
    PicoTextFieldState.disabled => colors.outline.subtle,
  };

  /// Resolves the fill color for this state.
  Color fillColor(PicoColorExtension colors, {required bool isEnabled}) =>
      isEnabled ? colors.background.card : colors.background.cardSecondary;

  /// Resolves the text color for this state.
  Color textColor(PicoColorExtension colors) => switch (this) {
    PicoTextFieldState.disabled => colors.foreground.disabled,
    _ => colors.foreground.main,
  };

  /// Resolves the label color for this state.
  Color labelColor(PicoColorExtension colors) => switch (this) {
    PicoTextFieldState.error => colors.foreground.error,
    _ => colors.foreground.main,
  };

  /// Resolves the helper/error text color for this state.
  Color helperColor(PicoColorExtension colors) => switch (this) {
    PicoTextFieldState.error => colors.foreground.error,
    _ => colors.foreground.subtle,
  };
}
