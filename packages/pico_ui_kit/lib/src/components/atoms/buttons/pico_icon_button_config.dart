import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';

/// Icon button variant types with color mappings.
enum PicoIconButtonVariant() {
  /// Filled icon button with primary color.
  filled,

  /// Filled icon button with tonal/secondary color.
  filledTonal,

  /// Outlined icon button with border.
  outlined,

  /// Standard icon button without background.
  standard;

  /// Returns the background color based on widget states.
  Color resolveBackgroundColor(
    Set<WidgetState> states,
    PicoColorExtension colors, {
    required bool isSelected,
  }) {
    if (isSelected) {
      if (states.contains(WidgetState.disabled)) {
        return colors.action.primary.disabled;
      }
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.hovered)) {
        return colors.action.primary.hover;
      }
      return colors.action.primary.active;
    }

    if (states.contains(WidgetState.disabled)) {
      return switch (this) {
        PicoIconButtonVariant.filled => colors.action.primary.disabled,
        PicoIconButtonVariant.filledTonal => colors.action.secondary.disabled,
        PicoIconButtonVariant.outlined ||
        PicoIconButtonVariant.standard => Colors.transparent,
      };
    }

    if (states.contains(WidgetState.pressed)) {
      return switch (this) {
        PicoIconButtonVariant.filled => colors.action.primary.hover,
        PicoIconButtonVariant.filledTonal => colors.action.secondary.hover,
        PicoIconButtonVariant.outlined || PicoIconButtonVariant.standard =>
          colors.action.primary.active.withValues(alpha: 0.1),
      };
    }

    if (states.contains(WidgetState.hovered)) {
      return switch (this) {
        PicoIconButtonVariant.filled => colors.action.primary.hover,
        PicoIconButtonVariant.filledTonal => colors.action.secondary.hover,
        PicoIconButtonVariant.outlined || PicoIconButtonVariant.standard =>
          colors.action.primary.active.withValues(alpha: 0.05),
      };
    }

    return switch (this) {
      PicoIconButtonVariant.filled => colors.action.primary.active,
      PicoIconButtonVariant.filledTonal => colors.action.secondary.active,
      PicoIconButtonVariant.outlined ||
      PicoIconButtonVariant.standard => Colors.transparent,
    };
  }

  /// Returns the foreground (icon) color based on widget states.
  Color resolveForegroundColor(
    Set<WidgetState> states,
    PicoColorExtension colors, {
    required bool isSelected,
  }) {
    if (isSelected) {
      if (states.contains(WidgetState.disabled)) {
        return colors.foreground.disabled;
      }
      return colors.foreground.inverse;
    }

    if (states.contains(WidgetState.disabled)) {
      return colors.foreground.disabled;
    }

    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return switch (this) {
        PicoIconButtonVariant.filled => colors.foreground.inverse,
        PicoIconButtonVariant.filledTonal => colors.foreground.main,
        PicoIconButtonVariant.outlined ||
        PicoIconButtonVariant.standard => colors.action.primary.hover,
      };
    }

    return switch (this) {
      PicoIconButtonVariant.filled => colors.foreground.inverse,
      PicoIconButtonVariant.filledTonal => colors.foreground.main,
      PicoIconButtonVariant.outlined ||
      PicoIconButtonVariant.standard => colors.foreground.main,
    };
  }

  /// Returns the border color based on widget states.
  Color? resolveBorderColor(
    Set<WidgetState> states,
    PicoColorExtension colors,
  ) {
    if (!isOutlined) return null;

    if (states.contains(WidgetState.disabled)) {
      return colors.outline.subtle;
    }

    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return colors.action.primary.hover;
    }

    return colors.outline.main;
  }

  /// Returns the default background color (active state).
  Color backgroundColor(
    PicoColorExtension colors, {
    required bool isSelected,
  }) => resolveBackgroundColor({}, colors, isSelected: isSelected);

  /// Returns the default foreground color (active state).
  Color foregroundColor(
    PicoColorExtension colors, {
    required bool isSelected,
  }) => resolveForegroundColor({}, colors, isSelected: isSelected);

  /// Returns true if this variant uses a filled style.
  bool get isFilled => switch (this) {
    PicoIconButtonVariant.filled || PicoIconButtonVariant.filledTonal => true,
    PicoIconButtonVariant.outlined || PicoIconButtonVariant.standard => false,
  };

  /// Returns true if this variant uses an outlined style.
  bool get isOutlined => this == PicoIconButtonVariant.outlined;
}

/// Icon button size presets with dimension mappings.
enum PicoIconButtonSize({
  /// Button container size.
  required final double buttonSize,

  /// Icon size within the button.
  required final double iconSize,
}) {
  /// Small icon button (32px).
  sm(buttonSize: 32, iconSize: 16),

  /// Medium icon button (40px).
  md(buttonSize: 40, iconSize: 24),

  /// Large icon button (48px).
  lg(buttonSize: 48, iconSize: 28);

  /// Returns the border radius for this size.
  BorderRadius borderRadius(PicoRadiusExtension radius) => switch (this) {
    PicoIconButtonSize.sm => radius.border.sm,
    PicoIconButtonSize.md => radius.border.md,
    PicoIconButtonSize.lg => radius.border.lg,
  };
}
