import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_action_colors.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';

/// Button style types.
enum PicoButtonStyle() {
  /// Filled button with solid background.
  filled,

  /// Outlined button with border.
  outlined,

  /// Text-only button without background or border.
  text,

  /// Ghost button — minimal, no background until hovered/pressed.
  ghost,
}

/// Button color variants.
enum PicoButtonColor() {
  /// Primary/brand color.
  primary,

  /// Secondary/neutral color.
  secondary,

  /// Destructive/danger color.
  destructive,

  /// Success color.
  success,
}

/// Extension methods for button styling.
extension PicoButtonStyleX on PicoButtonStyle {
  /// Returns the background color based on widget states and color variant.
  Color resolveBackgroundColor(
    Set<WidgetState> states,
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) {
    final actionColors = _getActionColors(colors, colorVariant);

    if (states.contains(WidgetState.disabled)) {
      return switch (this) {
        PicoButtonStyle.filled => actionColors.disabled,
        PicoButtonStyle.outlined ||
        PicoButtonStyle.text ||
        PicoButtonStyle.ghost => Colors.transparent,
      };
    }

    if (states.contains(WidgetState.pressed)) {
      return switch (this) {
        PicoButtonStyle.filled => actionColors.hover,
        PicoButtonStyle.outlined ||
        PicoButtonStyle.text ||
        PicoButtonStyle.ghost => actionColors.active.withValues(alpha: 0.1),
      };
    }

    if (states.contains(WidgetState.hovered)) {
      return switch (this) {
        PicoButtonStyle.filled => actionColors.hover,
        PicoButtonStyle.outlined ||
        PicoButtonStyle.text ||
        PicoButtonStyle.ghost => actionColors.active.withValues(alpha: 0.05),
      };
    }

    return switch (this) {
      PicoButtonStyle.filled => actionColors.active,
      PicoButtonStyle.outlined ||
      PicoButtonStyle.text ||
      PicoButtonStyle.ghost => Colors.transparent,
    };
  }

  /// Returns the foreground (text/icon) color based on widget states.
  ///
  /// Filled buttons use the inverse foreground (paper) on action backgrounds.
  /// Outlined, text, and ghost buttons use the action color.
  Color resolveForegroundColor(
    Set<WidgetState> states,
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) {
    final actionColors = _getActionColors(colors, colorVariant);

    if (states.contains(WidgetState.disabled)) {
      return colors.foreground.disabled;
    }

    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return switch (this) {
        PicoButtonStyle.filled => colors.foreground.inverse,
        PicoButtonStyle.outlined ||
        PicoButtonStyle.text ||
        PicoButtonStyle.ghost => actionColors.hover,
      };
    }

    return switch (this) {
      PicoButtonStyle.filled => colors.foreground.inverse,
      PicoButtonStyle.outlined ||
      PicoButtonStyle.text ||
      PicoButtonStyle.ghost => actionColors.active,
    };
  }

  /// Returns the border color based on widget states.
  Color? resolveBorderColor(
    Set<WidgetState> states,
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) {
    if (this != PicoButtonStyle.outlined) return null;

    final actionColors = _getActionColors(colors, colorVariant);

    if (states.contains(WidgetState.disabled)) {
      return actionColors.disabled;
    }

    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return actionColors.hover;
    }

    return actionColors.active;
  }

  /// Returns the default background color (active state).
  Color backgroundColor(
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) => resolveBackgroundColor({}, colors, colorVariant);

  /// Returns the default foreground color (active state).
  Color foregroundColor(
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) => resolveForegroundColor({}, colors, colorVariant);

  /// Returns true if this style uses a filled appearance.
  bool get isFilled => this == PicoButtonStyle.filled;

  /// Returns true if this style uses an outlined appearance.
  bool get isOutlined => this == PicoButtonStyle.outlined;

  /// Returns true if this style uses a text-only appearance.
  bool get isText => this == PicoButtonStyle.text;

  /// Returns true if this style uses a ghost appearance.
  bool get isGhost => this == PicoButtonStyle.ghost;

  PicoActionStateColors _getActionColors(
    PicoColorExtension colors,
    PicoButtonColor colorVariant,
  ) => switch (colorVariant) {
    PicoButtonColor.primary => colors.action.primary,
    PicoButtonColor.secondary => colors.action.secondary,
    PicoButtonColor.destructive => colors.action.destructive,
    PicoButtonColor.success => colors.action.success,
  };
}

/// Button size presets with dimension mappings.
enum PicoButtonSize({
  /// Minimum height for this size.
  required final double minHeight,

  /// Icon size for this size.
  required final double iconSize,
}) {
  /// Small button (32px height).
  sm(minHeight: 32, iconSize: 16),

  /// Medium button (40px height).
  md(minHeight: 40, iconSize: 20),

  /// Large button (48px height).
  lg(minHeight: 48, iconSize: 24);

  /// Returns the padding for this size.
  EdgeInsetsGeometry padding(PicoSpacingExtension spacing) => switch (this) {
    PicoButtonSize.sm => spacing.insets.horizontalMd.copyWith(
      top: spacing.xs,
      bottom: spacing.xs,
    ),
    PicoButtonSize.md => spacing.insets.horizontalLg.copyWith(
      top: spacing.sm,
      bottom: spacing.sm,
    ),
    PicoButtonSize.lg => spacing.insets.horizontalXl.copyWith(
      top: spacing.md,
      bottom: spacing.md,
    ),
  };

  /// Returns the border radius for this size.
  BorderRadius borderRadius(PicoRadiusExtension radius) => switch (this) {
    PicoButtonSize.sm => radius.border.sm,
    PicoButtonSize.md => radius.border.md,
    PicoButtonSize.lg => radius.border.lg,
  };

  /// Returns the text style for this size (without color).
  TextStyle textStyle(PicoTypographyExtension typography) => switch (this) {
    PicoButtonSize.sm => typography.button.small,
    PicoButtonSize.md => typography.button.regular,
    PicoButtonSize.lg => typography.button.large,
  };
}
