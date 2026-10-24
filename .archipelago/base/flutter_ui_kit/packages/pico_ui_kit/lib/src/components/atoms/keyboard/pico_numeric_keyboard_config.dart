import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/keyboard/pico_numeric_keyboard.dart'
    show PicoNumericKeyboard;

/// A single key entry for the bottom-left or bottom-right cell of
/// [PicoNumericKeyboard].
///
/// Use the factory constructors to create entries:
/// - [NumericKeyboardEntry.symbol] — text label with an optional tap handler
/// - [NumericKeyboardEntry.iconEntry] — icon with an optional tap handler
/// - [NumericKeyboardEntry.custom] — arbitrary widget with a tap handler
@immutable
class const NumericKeyboardEntry._({
  /// Text label, set for [NumericKeyboardEntry.symbol].
  final String? text,

  /// Icon, set for [NumericKeyboardEntry.iconEntry].
  final IconData? icon,

  /// Custom widget, set for [NumericKeyboardEntry.custom].
  final Widget? child,

  /// Called when this entry is tapped, in addition to any controller update.
  final VoidCallback? onTap,

  /// When `true` the [text] is appended to the shared text controller on tap.
  final bool appendsText = false,
}) {
  /// Creates an entry that displays a text symbol.
  ///
  /// When [appendsText] is `true` the symbol is appended to the controller
  /// (same behaviour as [NumericKeyboardConfig.decimal]'s `.` key).
  factory symbol(
    String text, {
    VoidCallback? onTap,
    bool appendsText = false,
  }) => NumericKeyboardEntry._(
    text: text,
    onTap: onTap,
    appendsText: appendsText,
  );

  /// Creates an entry that displays an icon.
  factory iconEntry(IconData icon, {VoidCallback? onTap}) =>
      NumericKeyboardEntry._(icon: icon, onTap: onTap);

  /// Creates an entry backed by an arbitrary widget.
  factory custom({required Widget child, VoidCallback? onTap}) =>
      NumericKeyboardEntry._(child: child, onTap: onTap);
}

/// Configuration for the bottom row of [PicoNumericKeyboard].
///
/// Defines what appears in the bottom-left and bottom-right cells of the
/// 3×4 numeric keyboard grid, plus optional operator keys for calculator mode.
///
/// Use one of the predefined factory constructors for common layouts:
/// - [NumericKeyboardConfig.pin] — empty left, backspace right
/// - [NumericKeyboardConfig.decimal] — decimal point left, backspace right
/// - [NumericKeyboardConfig.phone] — plus sign left, backspace right
/// - [NumericKeyboardConfig.calculator] — 4-column grid with operator column
/// - [NumericKeyboardConfig.custom] — fully custom widgets
@immutable
class const NumericKeyboardConfig({
  /// Text to display on the bottom-left button.
  ///
  /// Superseded by [leftBottomKey] when both are set.
  final String? leftButtonText,

  /// Icon to display on the bottom-right button.
  ///
  /// Superseded by [rightBottomKey] when both are set.
  final IconData? rightButtonIcon,

  /// Text to display on the bottom-right button.
  ///
  /// Superseded by [rightBottomKey] when both are set.
  final String? rightButtonText,

  /// Custom widget for the bottom-left button.
  ///
  /// Superseded by [leftBottomKey] when both are set.
  final Widget? leftButtonWidget,

  /// Custom widget for the bottom-right button.
  ///
  /// Superseded by [rightBottomKey] when both are set.
  final Widget? rightButtonWidget,

  /// Whether to show a biometric (fingerprint) button in the bottom-left cell.
  ///
  /// Superseded by [leftBottomKey] when both are set.
  final bool showBiometric = false,

  /// Entry for the bottom-left cell. Wins over all legacy left-button fields.
  final NumericKeyboardEntry? leftBottomKey,

  /// Entry for the bottom-right cell. Wins over all legacy right-button fields.
  final NumericKeyboardEntry? rightBottomKey,

  /// Operator labels shown in a dedicated right-side column (calculator mode).
  ///
  /// When non-null the keyboard switches to a 4-column grid. Expected to have
  /// exactly 4 entries (top → bottom): `['+', '−', '×', '÷']`.
  final List<String>? operatorKeys,

  /// Whether to include a thousand-separator key (`,`) in the bottom-left cell
  /// of calculator mode. Ignored in other modes.
  final bool showThousandSeparator = false,
}) {
  /// Creates a [NumericKeyboardConfig].
  this;

  /// Creates a PIN keyboard layout with empty left and backspace right.
  ///
  /// Optionally shows a biometric button in the bottom-left cell.
  factory pin({bool showBiometric = false}) => NumericKeyboardConfig(
    rightButtonIcon: Icons.backspace_outlined,
    showBiometric: showBiometric,
  );

  /// Creates a decimal keyboard layout with '.' left and backspace right.
  factory decimal() => const NumericKeyboardConfig(
    leftButtonText: '.',
    rightButtonIcon: Icons.backspace_outlined,
  );

  /// Creates a phone keyboard layout with '+' left and backspace right.
  factory phone() => const NumericKeyboardConfig(
    leftButtonText: '+',
    rightButtonIcon: Icons.backspace_outlined,
  );

  /// Creates a calculator keyboard layout with an operator column on the right.
  ///
  /// The keyboard becomes a 4-column grid:
  /// ```text
  /// 1  2  3  +
  /// 4  5  6  −
  /// 7  8  9  ×
  /// ,  0  .  ÷
  /// ```
  ///
  /// Supply [leftBottomKey] to override the `,` (thousand separator) slot.
  /// Supply [rightBottomKey] to override the `÷` slot.
  /// Set [showThousandSeparator] to `false` to leave the bottom-left cell empty.
  factory calculator({
    bool showThousandSeparator = true,
    NumericKeyboardEntry? leftBottomKey,
    NumericKeyboardEntry? rightBottomKey,
  }) => NumericKeyboardConfig(
    leftBottomKey:
        leftBottomKey ??
        (showThousandSeparator
            ? NumericKeyboardEntry.symbol(',', appendsText: true)
            : null),
    rightBottomKey:
        rightBottomKey ?? NumericKeyboardEntry.symbol('.', appendsText: true),
    operatorKeys: const ['+', '−', '×', '÷'],
    showThousandSeparator: showThousandSeparator,
  );

  /// Creates a fully custom keyboard layout with arbitrary widgets.
  factory custom({Widget? leftButton, Widget? rightButton}) =>
      NumericKeyboardConfig(
        leftButtonWidget: leftButton,
        rightButtonWidget: rightButton,
      );

  /// Whether this config activates calculator (4-column) mode.
  bool get isCalculatorMode => operatorKeys != null && operatorKeys!.isNotEmpty;
}

/// Visual style configuration for keyboard buttons.
@immutable
class const NumericKeyboardButtonStyle({
  /// Height of each keyboard button.
  final double height = 56,

  /// Text style for number keys.
  final TextStyle? textStyle,

  /// Splash color when button is pressed.
  final Color? splashColor,

  /// Highlight color when button is held.
  final Color? highlightColor,

  /// Shape of the button. Defaults to a rounded rectangle.
  final ShapeBorder? shape,

  /// Background color of each button.
  final Color? backgroundColor,

  /// Background color for operator keys in calculator mode.
  ///
  /// Defaults to a subtle tint of the primary action color.
  final Color? operatorBackgroundColor,

  /// Text style for operator keys. Falls back to [textStyle].
  final TextStyle? operatorTextStyle,
}) {
  /// Creates a [NumericKeyboardButtonStyle].
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumericKeyboardButtonStyle &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          textStyle == other.textStyle &&
          splashColor == other.splashColor &&
          highlightColor == other.highlightColor &&
          shape == other.shape &&
          backgroundColor == other.backgroundColor &&
          operatorBackgroundColor == other.operatorBackgroundColor &&
          operatorTextStyle == other.operatorTextStyle;

  @override
  int get hashCode => Object.hash(
    height,
    textStyle,
    splashColor,
    highlightColor,
    shape,
    backgroundColor,
    operatorBackgroundColor,
    operatorTextStyle,
  );

  @override
  String toString() =>
      'NumericKeyboardButtonStyle('
      'height: $height, '
      'textStyle: $textStyle, '
      'backgroundColor: $backgroundColor)';
}
