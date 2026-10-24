import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';

/// A customizable checkbox component following the design system.
///
/// Supports optional label, disabled state, and tristate with theme-aware
/// colors.
///
/// ```dart
/// PicoCheckbox(
///   value: isChecked,
///   onChanged: (value) => setState(() => isChecked = value),
///   label: 'Accept terms and conditions',
/// )
/// ```
class const PicoCheckbox({
  /// Whether the checkbox is checked.
  required final bool? value,

  /// Callback when the checkbox value changes.
  required final ValueChanged<bool?>? onChanged,

  /// Optional label displayed next to the checkbox.
  final String? label,

  /// Whether the checkbox is disabled.
  final bool isDisabled = false,

  /// Whether the checkbox is in an error state.
  final bool isError = false,

  /// Whether the checkbox can be in three states (checked, unchecked, null).
  final bool tristate = false,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoCheckbox].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final effectiveOnChanged = isDisabled ? null : onChanged;

    final checkbox = Checkbox(
      value: value,
      onChanged: effectiveOnChanged,
      tristate: tristate,
      activeColor: isError
          ? colors.foreground.error
          : colors.action.primary.active,
      checkColor: colors.foreground.inverse,
      side: BorderSide(color: _borderColor(colors), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    if (label == null) {
      return checkbox;
    }

    return GestureDetector(
      onTap: effectiveOnChanged != null
          ? () => effectiveOnChanged(!(value ?? false))
          : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          SizedBox(width: spacing.sm),
          Flexible(
            child: Text(
              label!,
              style: typography.body.small.copyWith(color: _labelColor(colors)),
            ),
          ),
        ],
      ),
    );
  }

  Color _borderColor(PicoColorExtension colors) {
    if (isDisabled) return colors.outline.subtle;
    if (isError) return colors.foreground.error;
    if (value ?? false) return colors.action.primary.active;
    return colors.outline.main;
  }

  Color _labelColor(PicoColorExtension colors) {
    if (isDisabled) return colors.foreground.disabled;
    if (isError) return colors.foreground.error;
    return colors.foreground.main;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool?>('value', value))
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<bool>('isDisabled', isDisabled))
      ..add(DiagnosticsProperty<bool>('isError', isError))
      ..add(DiagnosticsProperty<bool>('tristate', tristate))
      ..add(
        ObjectFlagProperty<ValueChanged<bool?>?>.has('onChanged', onChanged),
      );
  }
}
