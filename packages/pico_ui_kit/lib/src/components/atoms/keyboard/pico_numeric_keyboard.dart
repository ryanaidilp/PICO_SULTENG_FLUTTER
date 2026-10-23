import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_pin_input.dart'
    show PicoPinInput;
import 'package:pico_ui_kit/src/components/atoms/keyboard/pico_numeric_keyboard_config.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

export 'package:pico_ui_kit/src/components/atoms/keyboard/pico_numeric_keyboard_config.dart'
    show
        NumericKeyboardButtonStyle,
        NumericKeyboardConfig,
        NumericKeyboardEntry;

/// A highly configurable numeric keyboard widget with a 3×4 or 4×4 grid
/// layout.
///
/// Supports multiple predefined configurations for PIN, decimal, phone,
/// and calculator use cases, as well as fully custom button layouts.
///
/// Can drive any input widget via a shared [TextEditingController]:
///
/// ```dart
/// // Drive a PinInput
/// final controller = TextEditingController();
///
/// PicoPinInput(
///   length: 4,
///   controller: controller,
///   useNativeKeyboard: false,
/// )
/// PicoNumericKeyboard(
///   config: NumericKeyboardConfig.pin(showBiometric: true),
///   textController: controller,
///   maxLength: 4,
/// )
///
/// // Drive a TextField
/// TextField(controller: controller, readOnly: true)
/// PicoNumericKeyboard(
///   config: NumericKeyboardConfig.decimal(),
///   textController: controller,
/// )
///
/// // Calculator with custom operator column
/// PicoNumericKeyboard(
///   config: NumericKeyboardConfig.calculator(
///     showThousandSeparator: true,
///     leftBottomKey: NumericKeyboardEntry.symbol('+/-', onTap: onToggleSign),
///     rightBottomKey: NumericKeyboardEntry.symbol('÷', onTap: onDivide),
///   ),
///   onKeyPressed: onDigit,
/// )
/// ```
class const PicoNumericKeyboard({
  /// Configuration defining the bottom row layout and optional operator column.
  final NumericKeyboardConfig config = const NumericKeyboardConfig(),

  /// Called when a number key (0-9) or appending text key is pressed.
  final ValueChanged<String>? onKeyPressed,

  /// Called when the backspace button is pressed.
  final VoidCallback? onBackspace,

  /// Called when the custom left button is pressed.
  final VoidCallback? onCustomLeft,

  /// Called when the custom right button is pressed.
  final VoidCallback? onCustomRight,

  /// Called when the biometric button is pressed.
  final VoidCallback? onBiometric,

  /// Called when the input reaches [maxLength].
  final VoidCallback? onMaxLengthReached,

  /// Called when an operator key is pressed in calculator mode.
  ///
  /// Receives the operator string (e.g. `'+'`, `'−'`, `'×'`, `'÷'`).
  final ValueChanged<String>? onOperatorPressed,

  /// Optional [TextEditingController] to drive an input widget.
  ///
  /// When set, key presses automatically append to the controller's text
  /// and backspace removes the last character. Works with any widget
  /// that uses a [TextEditingController]: [PicoPinInput],
  /// [TextField], etc.
  ///
  /// The [onKeyPressed] and [onBackspace] callbacks still fire alongside
  /// the controller updates. Operator keys never mutate the controller —
  /// use [onOperatorPressed] for that.
  final TextEditingController? textController,

  /// Maximum input length. When reached, [onMaxLengthReached] is called
  /// and further key presses are ignored.
  final int? maxLength,

  /// Visual style configuration for buttons.
  final NumericKeyboardButtonStyle buttonStyle =
      const NumericKeyboardButtonStyle(),

  /// Horizontal spacing between buttons.
  final double horizontalSpacing = 0,

  /// Vertical spacing between rows.
  final double verticalSpacing = 0,

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback = true,

  /// Whether the keyboard is enabled.
  final bool enabled = true,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoNumericKeyboard].
  this;

  @override
  State<PicoNumericKeyboard> createState() => _PicoNumericKeyboardState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<NumericKeyboardConfig>('config', config))
      ..add(IntProperty('maxLength', maxLength))
      ..add(
        DiagnosticsProperty<TextEditingController?>(
          'textController',
          textController,
        ),
      )
      ..add(
        DiagnosticsProperty<NumericKeyboardButtonStyle>(
          'buttonStyle',
          buttonStyle,
        ),
      )
      ..add(DoubleProperty('horizontalSpacing', horizontalSpacing))
      ..add(DoubleProperty('verticalSpacing', verticalSpacing))
      ..add(
        DiagnosticsProperty<bool>('enableHapticFeedback', enableHapticFeedback),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onKeyPressed',
          onKeyPressed,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onBackspace', onBackspace))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onCustomLeft', onCustomLeft))
      ..add(
        ObjectFlagProperty<VoidCallback?>.has('onCustomRight', onCustomRight),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onBiometric', onBiometric))
      ..add(
        ObjectFlagProperty<VoidCallback?>.has(
          'onMaxLengthReached',
          onMaxLengthReached,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onOperatorPressed',
          onOperatorPressed,
        ),
      );
  }
}

class _PicoNumericKeyboardState() extends State<PicoNumericKeyboard> {
  int get _currentLength => widget.textController?.text.length ?? 0;

  Future<void> _triggerHaptic() async {
    if (!widget.enableHapticFeedback) return;
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  void _appendText(String text) {
    final controller = widget.textController;
    if (controller == null) return;
    controller
      ..text += text
      ..selection = TextSelection.collapsed(offset: controller.text.length);
  }

  void _removeLastChar() {
    final controller = widget.textController;
    if (controller == null || controller.text.isEmpty) return;
    controller
      ..text = controller.text.substring(0, controller.text.length - 1)
      ..selection = TextSelection.collapsed(offset: controller.text.length);
  }

  void _handleKeyPressed(String key) {
    if (!widget.enabled) return;
    if (widget.maxLength != null && _currentLength >= widget.maxLength!) {
      widget.onMaxLengthReached?.call();
      return;
    }

    _triggerHaptic();
    _appendText(key);
    widget.onKeyPressed?.call(key);

    if (widget.maxLength != null && _currentLength >= widget.maxLength!) {
      widget.onMaxLengthReached?.call();
    }
  }

  void _handleBackspace() {
    if (!widget.enabled) return;
    _triggerHaptic();
    _removeLastChar();
    widget.onBackspace?.call();
  }

  void _handleCustomLeft() {
    if (!widget.enabled) return;
    _triggerHaptic();
    final config = widget.config;
    if (config.leftButtonText != null) {
      _appendText(config.leftButtonText!);
      widget.onKeyPressed?.call(config.leftButtonText!);
    }
    widget.onCustomLeft?.call();
  }

  void _handleCustomRight() {
    if (!widget.enabled) return;
    _triggerHaptic();
    widget.onCustomRight?.call();
  }

  void _handleBiometric() {
    if (!widget.enabled) return;
    _triggerHaptic();
    widget.onBiometric?.call();
  }

  void _handleEntry(NumericKeyboardEntry entry) {
    if (!widget.enabled) return;
    _triggerHaptic();
    if (entry.appendsText && entry.text != null) {
      if (widget.maxLength != null && _currentLength >= widget.maxLength!) {
        widget.onMaxLengthReached?.call();
        return;
      }
      _appendText(entry.text!);
      widget.onKeyPressed?.call(entry.text!);
    }
    entry.onTap?.call();
  }

  void _handleOperator(String op) {
    if (!widget.enabled) return;
    _triggerHaptic();
    widget.onOperatorPressed?.call(op);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        widget.buttonStyle.textStyle ??
        context.typography.heading.h3.copyWith(fontWeight: FontWeight.w500);

    final effectiveSplashColor =
        widget.buttonStyle.splashColor ??
        context.colors.action.primary.active.withValues(alpha: 0.12);

    final effectiveHighlightColor =
        widget.buttonStyle.highlightColor ??
        context.colors.action.primary.active.withValues(alpha: 0.08);

    final effectiveOperatorBg =
        widget.buttonStyle.operatorBackgroundColor ??
        context.colors.action.primary.active.withValues(alpha: 0.08);

    final effectiveOperatorTextStyle =
        widget.buttonStyle.operatorTextStyle ?? effectiveTextStyle;

    if (widget.config.isCalculatorMode) {
      return _buildCalculatorGrid(
        effectiveTextStyle,
        effectiveSplashColor,
        effectiveHighlightColor,
        effectiveOperatorBg,
        effectiveOperatorTextStyle,
      );
    }

    return _buildStandardGrid(
      effectiveTextStyle,
      effectiveSplashColor,
      effectiveHighlightColor,
    );
  }

  // ── Standard 3-column grid (PIN / decimal / phone / custom) ──────────────

  Widget _buildStandardGrid(
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildRow(['1', '2', '3'], textStyle, splashColor, highlightColor),
      SizedBox(height: widget.verticalSpacing),
      _buildRow(['4', '5', '6'], textStyle, splashColor, highlightColor),
      SizedBox(height: widget.verticalSpacing),
      _buildRow(['7', '8', '9'], textStyle, splashColor, highlightColor),
      SizedBox(height: widget.verticalSpacing),
      _buildBottomRow(textStyle, splashColor, highlightColor),
    ],
  );

  Widget _buildRow(
    List<String> keys,
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (int i = 0; i < keys.length; i++) ...[
        if (i > 0) SizedBox(width: widget.horizontalSpacing),
        Expanded(
          child: _KeyButton(
            text: keys[i],
            textStyle: textStyle,
            height: widget.buttonStyle.height,
            splashColor: splashColor,
            highlightColor: highlightColor,
            shape: widget.buttonStyle.shape,
            backgroundColor: widget.buttonStyle.backgroundColor,
            enabled: widget.enabled,
            onTap: () => _handleKeyPressed(keys[i]),
          ),
        ),
      ],
    ],
  );

  Widget _buildBottomRow(
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(child: _buildLeftButton(textStyle, splashColor, highlightColor)),
      SizedBox(width: widget.horizontalSpacing),
      Expanded(
        child: _KeyButton(
          text: '0',
          textStyle: textStyle,
          height: widget.buttonStyle.height,
          splashColor: splashColor,
          highlightColor: highlightColor,
          shape: widget.buttonStyle.shape,
          backgroundColor: widget.buttonStyle.backgroundColor,
          enabled: widget.enabled,
          onTap: () => _handleKeyPressed('0'),
        ),
      ),
      SizedBox(width: widget.horizontalSpacing),
      Expanded(
        child: _buildRightButton(textStyle, splashColor, highlightColor),
      ),
    ],
  );

  Widget _buildLeftButton(
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) {
    final config = widget.config;

    // New entry API takes precedence over all legacy fields.
    if (config.leftBottomKey != null) {
      return _buildEntryButton(
        config.leftBottomKey!,
        textStyle,
        splashColor,
        highlightColor,
      );
    }

    if (config.leftButtonWidget != null) {
      return SizedBox(
        height: widget.buttonStyle.height,
        child: InkWell(
          onTap: widget.enabled ? _handleCustomLeft : null,
          borderRadius: BorderRadius.circular(8),
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Center(child: config.leftButtonWidget),
        ),
      );
    }

    if (config.showBiometric) {
      return _KeyButton(
        icon: Icons.fingerprint,
        textStyle: textStyle,
        height: widget.buttonStyle.height,
        splashColor: splashColor,
        highlightColor: highlightColor,
        shape: widget.buttonStyle.shape,
        backgroundColor: widget.buttonStyle.backgroundColor,
        enabled: widget.enabled,
        onTap: _handleBiometric,
      );
    }

    if (config.leftButtonText != null) {
      return _KeyButton(
        text: config.leftButtonText,
        textStyle: textStyle,
        height: widget.buttonStyle.height,
        splashColor: splashColor,
        highlightColor: highlightColor,
        shape: widget.buttonStyle.shape,
        backgroundColor: widget.buttonStyle.backgroundColor,
        enabled: widget.enabled,
        onTap: _handleCustomLeft,
      );
    }

    return SizedBox(height: widget.buttonStyle.height);
  }

  Widget _buildRightButton(
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) {
    final config = widget.config;

    // New entry API takes precedence over all legacy fields.
    if (config.rightBottomKey != null) {
      return _buildEntryButton(
        config.rightBottomKey!,
        textStyle,
        splashColor,
        highlightColor,
      );
    }

    if (config.rightButtonWidget != null) {
      return SizedBox(
        height: widget.buttonStyle.height,
        child: InkWell(
          onTap: widget.enabled ? _handleCustomRight : null,
          borderRadius: BorderRadius.circular(8),
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Center(child: config.rightButtonWidget),
        ),
      );
    }

    if (config.rightButtonIcon != null) {
      return _KeyButton(
        icon: config.rightButtonIcon,
        textStyle: textStyle,
        height: widget.buttonStyle.height,
        splashColor: splashColor,
        highlightColor: highlightColor,
        shape: widget.buttonStyle.shape,
        backgroundColor: widget.buttonStyle.backgroundColor,
        enabled: widget.enabled,
        onTap: config.rightButtonIcon == Icons.backspace_outlined
            ? _handleBackspace
            : _handleCustomRight,
      );
    }

    if (config.rightButtonText != null) {
      return _KeyButton(
        text: config.rightButtonText,
        textStyle: textStyle,
        height: widget.buttonStyle.height,
        splashColor: splashColor,
        highlightColor: highlightColor,
        shape: widget.buttonStyle.shape,
        backgroundColor: widget.buttonStyle.backgroundColor,
        enabled: widget.enabled,
        onTap: _handleCustomRight,
      );
    }

    return SizedBox(height: widget.buttonStyle.height);
  }

  Widget _buildEntryButton(
    NumericKeyboardEntry entry,
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
  ) {
    if (entry.child != null) {
      return SizedBox(
        height: widget.buttonStyle.height,
        child: InkWell(
          onTap: widget.enabled ? () => _handleEntry(entry) : null,
          borderRadius: BorderRadius.circular(8),
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Center(child: entry.child),
        ),
      );
    }

    return _KeyButton(
      text: entry.text,
      icon: entry.icon,
      textStyle: textStyle,
      height: widget.buttonStyle.height,
      splashColor: splashColor,
      highlightColor: highlightColor,
      shape: widget.buttonStyle.shape,
      backgroundColor: widget.buttonStyle.backgroundColor,
      enabled: widget.enabled,
      onTap: () => _handleEntry(entry),
    );
  }

  // ── Calculator 4-column grid ─────────────────────────────────────────────

  /// Builds the 4-column calculator layout:
  /// ```text
  /// 1  2  3  +
  /// 4  5  6  −
  /// 7  8  9  ×
  /// ,  0  .  ÷
  /// ```
  Widget _buildCalculatorGrid(
    TextStyle textStyle,
    Color splashColor,
    Color highlightColor,
    Color operatorBg,
    TextStyle operatorTextStyle,
  ) {
    final ops = widget.config.operatorKeys!;

    Widget opButton(String op) => _KeyButton(
      text: op,
      textStyle: operatorTextStyle,
      height: widget.buttonStyle.height,
      splashColor: splashColor,
      highlightColor: highlightColor,
      shape: widget.buttonStyle.shape,
      backgroundColor: operatorBg,
      enabled: widget.enabled,
      onTap: () => _handleOperator(op),
    );

    Widget digitButton(String d) => _KeyButton(
      text: d,
      textStyle: textStyle,
      height: widget.buttonStyle.height,
      splashColor: splashColor,
      highlightColor: highlightColor,
      shape: widget.buttonStyle.shape,
      backgroundColor: widget.buttonStyle.backgroundColor,
      enabled: widget.enabled,
      onTap: () => _handleKeyPressed(d),
    );

    Widget calcRow(List<String> digits, String op) => Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) SizedBox(width: widget.horizontalSpacing),
          Expanded(child: digitButton(digits[i])),
        ],
        SizedBox(width: widget.horizontalSpacing),
        Expanded(child: opButton(op)),
      ],
    );

    final leftEntry = widget.config.leftBottomKey;
    final rightEntry = widget.config.rightBottomKey;

    final Widget bottomLeft = leftEntry != null
        ? _buildEntryButton(leftEntry, textStyle, splashColor, highlightColor)
        : SizedBox(height: widget.buttonStyle.height);

    final Widget bottomRight = rightEntry != null
        ? _buildEntryButton(rightEntry, textStyle, splashColor, highlightColor)
        : SizedBox(height: widget.buttonStyle.height);

    assert(ops.length == 4, 'operatorKeys must have exactly 4 entries');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        calcRow(['1', '2', '3'], ops[0]),
        SizedBox(height: widget.verticalSpacing),
        calcRow(['4', '5', '6'], ops[1]),
        SizedBox(height: widget.verticalSpacing),
        calcRow(['7', '8', '9'], ops[2]),
        SizedBox(height: widget.verticalSpacing),
        Row(
          children: [
            Expanded(child: bottomLeft),
            SizedBox(width: widget.horizontalSpacing),
            Expanded(child: digitButton('0')),
            SizedBox(width: widget.horizontalSpacing),
            Expanded(child: bottomRight),
            SizedBox(width: widget.horizontalSpacing),
            Expanded(child: opButton(ops[3])),
          ],
        ),
      ],
    );
  }
}

/// Internal button widget for keyboard keys.
class const _KeyButton({
  required final TextStyle textStyle,
  required final double height,
  required final Color splashColor,
  required final Color highlightColor,
  required final bool enabled,
  required final VoidCallback onTap,
  final String? text,
  final IconData? icon,
  final ShapeBorder? shape,
  final Color? backgroundColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final effectiveShape =
        shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    return SizedBox(
      height: height,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        shape: effectiveShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: effectiveShape,
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: textStyle.fontSize ?? 24,
                    color: enabled
                        ? textStyle.color ?? context.colors.foreground.main
                        : (textStyle.color ?? context.colors.foreground.main)
                              .withValues(alpha: 0.38),
                  )
                : Text(
                    text ?? '',
                    style: textStyle.copyWith(
                      color: enabled
                          ? null
                          : (textStyle.color ?? context.colors.foreground.main)
                                .withValues(alpha: 0.38),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(DiagnosticsProperty<IconData?>('icon', icon))
      ..add(DiagnosticsProperty<TextStyle>('textStyle', textStyle))
      ..add(DoubleProperty('height', height))
      ..add(ColorProperty('splashColor', splashColor))
      ..add(ColorProperty('highlightColor', highlightColor))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}
