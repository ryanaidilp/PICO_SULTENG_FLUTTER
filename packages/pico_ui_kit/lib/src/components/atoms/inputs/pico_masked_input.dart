import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text input with configurable mask pattern for formatted input.
///
/// Mask characters:
/// - `#` — digit (0-9)
/// - `A` — letter (a-z, A-Z)
/// - `*` — any character
///
/// All other characters in the mask are treated as literal separators
/// and are automatically inserted.
///
/// ```dart
/// PicoMaskedInput(
///   mask: '##/##/####',
///   label: 'Date of Birth',
///   hint: 'DD/MM/YYYY',
///   onChanged: (value) => print('Raw: $value'),
/// )
///
/// PicoMaskedInput(
///   mask: '### ### ####',
///   label: 'Phone Number',
///   keyboardType: TextInputType.phone,
/// )
/// ```
class const PicoMaskedInput({
  /// The mask pattern string.
  ///
  /// - `#` = digit
  /// - `A` = letter
  /// - `*` = any character
  required final String mask,

  /// Text editing controller.
  final TextEditingController? controller,

  /// Focus node for the input.
  final FocusNode? focusNode,

  /// Label displayed above the input.
  final String? label,

  /// Placeholder text.
  final String? hint,

  /// Helper text displayed below the input.
  final String? helperText,

  /// Error text displayed below the input.
  final String? errorText,

  /// Icon displayed at the start of the input.
  final Widget? prefixIcon,

  /// Icon displayed at the end of the input.
  final Widget? suffixIcon,

  /// Whether the input is enabled.
  final bool enabled = true,

  /// Whether the input is read-only.
  final bool readOnly = false,

  /// Whether to auto-focus on mount.
  final bool autofocus = false,

  /// Keyboard type. Defaults based on mask content.
  final TextInputType? keyboardType,

  /// Text input action.
  final TextInputAction? textInputAction,

  /// Called with the unmasked (raw) value when text changes.
  final ValueChanged<String>? onChanged,

  /// Called when submitted.
  final ValueChanged<String>? onSubmitted,

  /// Called when tapped.
  final VoidCallback? onTap,

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization = TextCapitalization.none,

  /// Text style for the input text.
  final TextStyle? textStyle,

  /// Style for the label.
  final TextStyle? labelStyle,

  /// Style for the hint text.
  final TextStyle? hintStyle,

  /// Style for the error text.
  final TextStyle? errorStyle,

  /// Fill color for the input.
  final Color? fillColor,

  /// Default border color.
  final Color? borderColor,

  /// Focused border color.
  final Color? focusedBorderColor,

  /// Error border color.
  final Color? errorBorderColor,

  /// Border radius.
  final BorderRadius? borderRadius,

  /// Content padding inside the input.
  final EdgeInsetsGeometry? contentPadding,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoMaskedInput].
  this;

  @override
  State<PicoMaskedInput> createState() => _PicoMaskedInputState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('mask', mask))
      ..add(
        DiagnosticsProperty<TextEditingController?>('controller', controller),
      )
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode))
      ..add(StringProperty('label', label))
      ..add(StringProperty('hint', hint))
      ..add(StringProperty('helperText', helperText))
      ..add(StringProperty('errorText', errorText))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<bool>('readOnly', readOnly))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<TextInputType?>('keyboardType', keyboardType))
      ..add(EnumProperty<TextInputAction?>('textInputAction', textInputAction))
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
}

class _PicoMaskedInputState() extends State<PicoMaskedInput> {
  late TextEditingController _controller;
  late _MaskTextInputFormatter _formatter;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _formatter = _MaskTextInputFormatter(mask: widget.mask);
  }

  @override
  void didUpdateWidget(PicoMaskedInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.mask != oldWidget.mask) {
      _formatter = _MaskTextInputFormatter(mask: widget.mask);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  TextInputType get _effectiveKeyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    // Infer from mask: if only digits, use number keyboard
    final hasOnlyDigitSlots = widget.mask
        .replaceAll(RegExp('[^#A*]'), '')
        .replaceAll('#', '')
        .isEmpty;
    if (hasOnlyDigitSlots && widget.mask.contains('#')) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  void _handleChanged(String maskedValue) {
    final rawValue = _formatter.unmaskedValue;
    widget.onChanged?.call(rawValue);
  }

  void _handleSubmitted(String maskedValue) {
    final rawValue = _formatter.unmaskedValue;
    widget.onSubmitted?.call(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(8);
    final effectiveBorderColor = widget.borderColor ?? colorScheme.outline;
    final effectiveFocusedBorderColor =
        widget.focusedBorderColor ?? colorScheme.primary;
    final effectiveErrorBorderColor =
        widget.errorBorderColor ?? colorScheme.error;
    final effectiveContentPadding =
        widget.contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style:
                widget.labelStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _hasError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          keyboardType: _effectiveKeyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: [_formatter],
          onChanged: _handleChanged,
          onSubmitted: _handleSubmitted,
          onTap: widget.onTap,
          style: widget.textStyle,
          decoration: InputDecoration(
            hintText: widget.hint ?? _formatter.maskAsHint,
            hintStyle: widget.hintStyle,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            filled: widget.fillColor != null,
            fillColor: widget.fillColor,
            contentPadding: effectiveContentPadding,
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: _hasError
                    ? effectiveErrorBorderColor
                    : effectiveBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: _hasError
                    ? effectiveErrorBorderColor
                    : effectiveFocusedBorderColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(color: effectiveErrorBorderColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: effectiveErrorBorderColor,
                width: 2,
              ),
            ),
            counterText: '',
          ),
        ),
        if (_hasError || widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            _hasError ? widget.errorText! : widget.helperText!,
            style:
                widget.errorStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: _hasError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

/// Internal text input formatter that applies a mask pattern.
class _MaskTextInputFormatter({
  /// The mask pattern.
  required final String mask,
}) extends TextInputFormatter {
  String _lastUnmasked = '';

  /// Returns the current unmasked (raw) value.
  String get unmaskedValue => _lastUnmasked;

  /// Returns the mask pattern as a hint string (e.g. "##/##/####" stays as-is).
  String get maskAsHint => mask;

  bool _isMaskChar(String char) => char == '#' || char == 'A' || char == '*';

  bool _matchesMaskChar(String maskChar, String inputChar) {
    switch (maskChar) {
      case '#':
        return RegExp('[0-9]').hasMatch(inputChar);
      case 'A':
        return RegExp('[a-zA-Z]').hasMatch(inputChar);
      case '*':
        return true;
      default:
        return false;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // Extract raw characters (those matching mask slots)
    final rawChars = <String>[];
    var maskIndex = 0;
    for (var i = 0; i < newText.length && maskIndex < mask.length; i++) {
      final char = newText[i];
      // Skip separator characters in the input
      if (!_isMaskChar(mask[maskIndex])) {
        if (char == mask[maskIndex]) {
          maskIndex++;
          continue;
        }
        // Skip the separator in mask and try to match
        maskIndex++;
        i--; // Re-process the same input char
        continue;
      }
      if (_matchesMaskChar(mask[maskIndex], char)) {
        rawChars.add(char);
        maskIndex++;
      }
    }

    // Also handle case where user types raw characters without separators
    if (rawChars.isEmpty && newText.isNotEmpty) {
      for (var i = 0; i < newText.length; i++) {
        rawChars.add(newText[i]);
      }
    }

    // Build masked string from raw characters
    final buffer = StringBuffer();
    var rawIndex = 0;
    for (var i = 0; i < mask.length && rawIndex < rawChars.length; i++) {
      if (_isMaskChar(mask[i])) {
        if (_matchesMaskChar(mask[i], rawChars[rawIndex])) {
          buffer.write(rawChars[rawIndex]);
          rawIndex++;
        } else {
          break; // Invalid character for this mask position
        }
      } else {
        buffer.write(mask[i]);
      }
    }

    final maskedText = buffer.toString();
    _lastUnmasked = rawChars.take(rawIndex).join();

    // Calculate cursor position
    var cursorOffset = maskedText.length;
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      // Deleting: position cursor at appropriate place
      cursorOffset = newValue.selection.baseOffset;
      // If cursor lands on a separator, move it back
      if (cursorOffset > 0 &&
          cursorOffset <= mask.length &&
          !_isMaskChar(mask[cursorOffset - 1])) {
        cursorOffset--;
      }
      cursorOffset = cursorOffset.clamp(0, maskedText.length);
    }

    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
