import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// Visual styles for [PicoOtpInput] cells.
enum PicoOtpCellStyle() {
  /// Individual boxed cells with borders.
  boxed,

  /// Cells with only a bottom border (underline).
  underlined,

  /// Filled cells with a background color.
  filled,
}

/// An OTP (One-Time Password) input widget with boxed digit cells
/// and resend countdown functionality.
///
/// ```dart
/// PicoOtpInput(
///   length: 6,
///   title: 'Enter verification code',
///   subtitle: 'We sent a code to your phone',
///   onCompleted: (otp) => verifyOtp(otp),
///   onResend: () => sendOtp(),
///   countdownDuration: Duration(seconds: 60),
/// )
/// ```
class const PicoOtpInput({
  /// Number of OTP digits.
  final int length = 6,

  /// Called when all digits have been entered.
  final ValueChanged<String>? onCompleted,

  /// Called when the resend button is pressed.
  final VoidCallback? onResend,

  /// Called whenever the OTP value changes.
  final ValueChanged<String>? onChanged,

  /// Duration of the resend countdown.
  final Duration countdownDuration = const Duration(seconds: 60),

  /// Title text displayed above the OTP input.
  final String? title,

  /// Subtitle text displayed below the title.
  final String? subtitle,

  /// Error message displayed below the OTP input.
  final String? errorText,

  /// Text for the resend button.
  final String resendText = 'Resend code',

  /// Prefix for the countdown text (e.g. "Resend in ").
  final String countdownPrefix = 'Resend in ',

  /// Suffix for the countdown text (e.g. "s").
  final String countdownSuffix = 's',

  /// Visual style for the cells.
  final PicoOtpCellStyle cellStyle = PicoOtpCellStyle.boxed,

  /// Whether to obscure entered digits.
  final bool obscure = false,

  /// Character used for obscured display.
  final String obscureCharacter = '\u2022',

  /// Whether to auto-focus on mount.
  final bool autofocus = true,

  /// Whether the input is enabled.
  final bool enabled = true,

  /// Style for the title text.
  final TextStyle? titleStyle,

  /// Style for the subtitle text.
  final TextStyle? subtitleStyle,

  /// Style for the resend button text.
  final TextStyle? resendTextStyle,

  /// Text style for the OTP digits.
  final TextStyle? textStyle,

  /// Size of each cell (width and height).
  final double cellSize = 48.0,

  /// Spacing between cells.
  final double cellSpacing = 12.0,

  /// Default border color.
  final Color? borderColor,

  /// Focused cell border color.
  final Color? focusedBorderColor,

  /// Error state border color.
  final Color? errorBorderColor,

  /// Default cell fill color.
  final Color? fillColor,

  /// Focused cell fill color.
  final Color? focusedFillColor,

  /// Border radius for cells.
  final BorderRadius? borderRadius,

  /// Border width.
  final double borderWidth = 1.5,

  /// Whether to show a cursor in the active cell.
  final bool showCursor = true,

  /// Cursor color.
  final Color? cursorColor,

  /// Optional external controller for the OTP value.
  final TextEditingController? controller,

  /// Screen reader label for the code entry.
  final String semanticLabel = 'One-time passcode entry',
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoOtpInput].
  this;

  @override
  State<PicoOtpInput> createState() => _PicoOtpInputState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(
        DiagnosticsProperty<Duration>('countdownDuration', countdownDuration),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle))
      ..add(StringProperty('errorText', errorText))
      ..add(StringProperty('resendText', resendText))
      ..add(StringProperty('countdownPrefix', countdownPrefix))
      ..add(StringProperty('countdownSuffix', countdownSuffix))
      ..add(EnumProperty<PicoOtpCellStyle>('cellStyle', cellStyle))
      ..add(DiagnosticsProperty<bool>('obscure', obscure))
      ..add(StringProperty('obscureCharacter', obscureCharacter))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<TextStyle?>('titleStyle', titleStyle))
      ..add(DiagnosticsProperty<TextStyle?>('subtitleStyle', subtitleStyle))
      ..add(DiagnosticsProperty<TextStyle?>('resendTextStyle', resendTextStyle))
      ..add(DiagnosticsProperty<TextStyle?>('textStyle', textStyle))
      ..add(DoubleProperty('cellSize', cellSize))
      ..add(DoubleProperty('cellSpacing', cellSpacing))
      ..add(ColorProperty('borderColor', borderColor))
      ..add(ColorProperty('focusedBorderColor', focusedBorderColor))
      ..add(ColorProperty('errorBorderColor', errorBorderColor))
      ..add(ColorProperty('fillColor', fillColor))
      ..add(ColorProperty('focusedFillColor', focusedFillColor))
      ..add(DiagnosticsProperty<BorderRadius?>('borderRadius', borderRadius))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DiagnosticsProperty<bool>('showCursor', showCursor))
      ..add(ColorProperty('cursorColor', cursorColor))
      ..add(
        DiagnosticsProperty<TextEditingController?>('controller', controller),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onResend', onResend))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      );
  }
}

class _PicoOtpInputState()
    extends State<PicoOtpInput>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _cursorController;

  Timer? _countdownTimer;
  String _lastText = '';
  int _remainingSeconds = 0;
  bool _canResend = false;

  String get _otp => _controller.text;
  int get _filledCount => _otp.length;
  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChanged);
    _focusNode = FocusNode();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startCountdown();
  }

  @override
  void didUpdateWidget(PicoOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _cursorController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
    // The controller also notifies on selection-only changes; report each
    // value once so onCompleted cannot fire twice for one code.
    if (_otp == _lastText) return;
    _lastText = _otp;
    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length) {
      widget.onCompleted?.call(_otp);
    }
  }

  void _startCountdown() {
    _remainingSeconds = widget.countdownDuration.inSeconds;
    _canResend = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _canResend = true;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  void _handleResend() {
    widget.onResend?.call();
    _startCountdown();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
  }

  /// Fills every cell from the clipboard. The hidden field has no paste
  /// menu, so a long press on the cells is the paste gesture.
  Future<void> _handlePaste() async {
    if (!widget.enabled) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || !mounted) return;
    final code = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        widget.borderColor ?? context.colors.outline.main;
    final effectiveFocusedBorderColor =
        widget.focusedBorderColor ?? context.colors.action.primary.active;
    final effectiveErrorBorderColor =
        widget.errorBorderColor ?? context.colors.foreground.error;
    final effectiveFillColor =
        widget.fillColor ?? context.colors.background.subtle;
    final effectiveFocusedFillColor =
        widget.focusedFillColor ?? context.colors.background.subtle;
    final effectiveTextStyle =
        widget.textStyle ??
        context.typography.heading.h3.copyWith(fontWeight: FontWeight.w600);
    final effectiveCursorColor =
        widget.cursorColor ?? context.colors.action.primary.active;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style:
                    widget.titleStyle ??
                    context.typography.heading.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            // Subtitle
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style:
                    widget.subtitleStyle ??
                    context.typography.body.regular.copyWith(
                      color: context.colors.foreground.subtle,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // OTP cells
            Semantics(
              label: widget.semanticLabel,
              value: _hasError
                  ? 'Error: ${widget.errorText}'
                  : '$_filledCount of ${widget.length} digits entered',
              liveRegion: true,
              child: GestureDetector(
                onTap: _handleTap,
                onLongPress: _handlePaste,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Its own semantics are excluded — the Semantics above
                    // already describes this whole control (label + live
                    // progress), so exposing the invisible TextField too
                    // would just produce a confusing extra "text field,
                    // blank" node for screen reader users.
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: 0,
                        child: SizedBox(
                          height: 1,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: widget.autofocus,
                            enabled: widget.enabled,
                            keyboardType: TextInputType.number,
                            // iOS offers the code from Messages; Android maps
                            // this to its SMS one-time-code autofill hint.
                            autofillHints: const [AutofillHints.oneTimeCode],
                            maxLength: widget.length,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(widget.length),
                            ],
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.length, (index) {
                        final isFilled = index < _filledCount;
                        final isFocused =
                            _focusNode.hasFocus && index == _filledCount;
                        final char = isFilled ? _otp[index] : '';
                        final displayChar = widget.obscure && isFilled
                            ? widget.obscureCharacter
                            : char;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < widget.length - 1
                                ? widget.cellSpacing
                                : 0,
                          ),
                          child: _OtpCell(
                            char: displayChar,
                            isFocused: isFocused,
                            isFilled: isFilled,
                            hasError: _hasError,
                            size: widget.cellSize,
                            cellStyle: widget.cellStyle,
                            borderColor: effectiveBorderColor,
                            focusedBorderColor: effectiveFocusedBorderColor,
                            errorBorderColor: effectiveErrorBorderColor,
                            fillColor: effectiveFillColor,
                            focusedFillColor: effectiveFocusedFillColor,
                            textStyle: effectiveTextStyle,
                            borderRadius: widget.borderRadius,
                            borderWidth: widget.borderWidth,
                            showCursor: widget.showCursor && isFocused,
                            cursorColor: effectiveCursorColor,
                            cursorAnimation: _cursorController,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Error text
            if (_hasError) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorText!,
                style: context.typography.body.small.copyWith(
                  color: context.colors.foreground.error,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Resend button / countdown
            if (_canResend)
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: _handleResend,
                  child: Text(
                    widget.resendText,
                    style:
                        widget.resendTextStyle ??
                        context.typography.body.regular.copyWith(
                          color: context.colors.action.primary.active,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              )
            else
              Text(
                '${widget.countdownPrefix}$_remainingSeconds${widget.countdownSuffix}',
                style:
                    widget.resendTextStyle ??
                    context.typography.body.regular.copyWith(
                      color: context.colors.foreground.subtle,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Internal widget for a single OTP cell.
class const _OtpCell({
  required final String char,
  required final bool isFocused,
  required final bool isFilled,
  required final bool hasError,
  required final double size,
  required final PicoOtpCellStyle cellStyle,
  required final Color borderColor,
  required final Color focusedBorderColor,
  required final Color errorBorderColor,
  required final Color fillColor,
  required final Color focusedFillColor,
  required final TextStyle textStyle,
  required final double borderWidth,
  required final bool showCursor,
  required final Color cursorColor,
  required final Animation<double> cursorAnimation,
  final BorderRadius? borderRadius,
}) extends StatelessWidget {
  Color get _effectiveBorderColor {
    if (hasError) return errorBorderColor;
    if (isFocused) return focusedBorderColor;
    return borderColor;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(8);

    final Widget child = Center(
      child: showCursor
          ? FadeTransition(
              opacity: cursorAnimation,
              child: Container(
                width: 2,
                height: size * 0.5,
                decoration: BoxDecoration(
                  color: cursorColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            )
          : Text(char, style: textStyle),
    );

    return switch (cellStyle) {
      PicoOtpCellStyle.boxed => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          border: Border.all(
            color: _effectiveBorderColor,
            width: isFocused ? borderWidth + 0.5 : borderWidth,
          ),
        ),
        child: child,
      ),
      PicoOtpCellStyle.underlined => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _effectiveBorderColor,
              width: isFocused ? borderWidth + 1 : borderWidth,
            ),
          ),
        ),
        child: child,
      ),
      PicoOtpCellStyle.filled => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          color: isFocused ? focusedFillColor : fillColor,
          border: Border.all(
            color: _effectiveBorderColor,
            width: isFocused ? borderWidth + 0.5 : borderWidth,
          ),
        ),
        child: child,
      ),
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('char', char))
      ..add(DiagnosticsProperty<bool>('isFocused', isFocused))
      ..add(DiagnosticsProperty<bool>('isFilled', isFilled))
      ..add(DiagnosticsProperty<bool>('hasError', hasError))
      ..add(DoubleProperty('size', size))
      ..add(EnumProperty<PicoOtpCellStyle>('cellStyle', cellStyle))
      ..add(ColorProperty('borderColor', borderColor))
      ..add(ColorProperty('focusedBorderColor', focusedBorderColor))
      ..add(ColorProperty('errorBorderColor', errorBorderColor))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DiagnosticsProperty<bool>('showCursor', showCursor))
      ..add(ColorProperty('cursorColor', cursorColor));
  }
}
