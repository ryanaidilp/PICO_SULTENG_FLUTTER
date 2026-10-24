import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:pico_ui_kit/src/components/atoms/keyboard/pico_numeric_keyboard.dart'
    show PicoNumericKeyboard;
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// A PIN input that displays dot indicators for entered and remaining digits.
///
/// Works with both the native system keyboard and a custom
/// [PicoNumericKeyboard] via a shared [TextEditingController].
///
/// ```dart
/// // With native keyboard (default)
/// PicoPinInput(
///   length: 4,
///   onCompleted: (pin) => print('PIN: $pin'),
/// )
///
/// // With custom numeric keyboard
/// final controller = TextEditingController();
///
/// PicoPinInput(
///   length: 4,
///   controller: controller,
///   useNativeKeyboard: false,
///   onCompleted: (pin) => print('PIN: $pin'),
/// )
/// PicoNumericKeyboard(
///   config: NumericKeyboardConfig.pin(showBiometric: true),
///   textController: controller,
///   maxLength: 4,
/// )
/// ```
class const PicoPinInput({
  /// Number of PIN digits.
  final int length = 6,

  /// Called when all digits have been entered.
  final ValueChanged<String>? onCompleted,

  /// Called whenever the PIN value changes.
  final ValueChanged<String>? onChanged,

  /// Whether to auto-focus on mount. Only applies when [useNativeKeyboard]
  /// is true.
  final bool autofocus = false,

  /// Whether the input is enabled.
  final bool enabled = true,

  /// Whether to show the native system keyboard on tap.
  ///
  /// Set to `false` when using a custom [PicoNumericKeyboard]
  /// with a shared [controller].
  final bool useNativeKeyboard = true,

  /// Error text that triggers error state and shake animation.
  final String? errorText,

  /// Whether to shake on error.
  final bool enableShakeOnError = true,

  /// Whether to provide haptic feedback on error.
  final bool enableHapticFeedback = true,

  /// Diameter of each dot indicator.
  final double dotSize = 16.0,

  /// Spacing between dot indicators.
  final double dotSpacing = 16.0,

  /// Color for filled dots (entered digits).
  /// Defaults to [ColorScheme.onSurface].
  final Color? activeColor,

  /// Color for empty dots (remaining digits).
  /// Defaults to [ColorScheme.outlineVariant].
  final Color? inactiveColor,

  /// Color for dots and error text in error state.
  /// Defaults to [ColorScheme.error].
  final Color? errorColor,

  /// Optional external controller for the PIN value.
  ///
  /// Share this controller with [PicoNumericKeyboard]'s
  /// `textController` to connect the two widgets.
  final TextEditingController? controller,

  /// Optional title displayed above the PIN dots.
  final String? title,

  /// Optional subtitle displayed below the title.
  final String? subtitle,

  /// Style for the title text. Defaults to the theme heading h4 style.
  final TextStyle? titleStyle,

  /// Style for the subtitle text. Defaults to the theme body regular style.
  final TextStyle? subtitleStyle,

  /// How long the most-recently entered digit is shown before it becomes a dot.
  ///
  /// Mirrors iOS native PIN entry: the last typed digit briefly flashes as a
  /// character before being masked. Rapid typing cancels the previous reveal
  /// and restarts the timer for the new digit.
  ///
  /// Set to `null` to disable the reveal entirely (dots appear immediately).
  /// Defaults to 600 ms.
  final Duration? revealDuration = const Duration(milliseconds: 600),
  super.key,
}) extends StatefulWidget {
  /// Creates a [PicoPinInput].
  this;

  @override
  State<PicoPinInput> createState() => _PicoPinInputState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<bool>('useNativeKeyboard', useNativeKeyboard))
      ..add(StringProperty('errorText', errorText))
      ..add(DiagnosticsProperty<bool>('enableShakeOnError', enableShakeOnError))
      ..add(
        DiagnosticsProperty<bool>('enableHapticFeedback', enableHapticFeedback),
      )
      ..add(DoubleProperty('dotSize', dotSize))
      ..add(DoubleProperty('dotSpacing', dotSpacing))
      ..add(ColorProperty('activeColor', activeColor))
      ..add(ColorProperty('inactiveColor', inactiveColor))
      ..add(ColorProperty('errorColor', errorColor))
      ..add(
        DiagnosticsProperty<TextEditingController?>('controller', controller),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle))
      ..add(DiagnosticsProperty<TextStyle?>('titleStyle', titleStyle))
      ..add(DiagnosticsProperty<TextStyle?>('subtitleStyle', subtitleStyle))
      ..add(DiagnosticsProperty<Duration?>('revealDuration', revealDuration))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      );
  }
}

class _PicoPinInputState()
    extends State<PicoPinInput>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  FocusNode? _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String? _previousErrorText;

  /// Whether the dots should currently render in the error color.
  ///
  /// Set on a fresh error transition (see [didUpdateWidget]) and cleared the
  /// instant the user starts a new attempt from an empty pin (see
  /// [_handleTextChanged]) or once the caller clears `errorText` — whichever
  /// happens first. Kept separate from [_hasError] (the raw prop check,
  /// which still gates the error message text below the dots) so the dots
  /// reset per-keystroke instead of staying red for as long as the caller's
  /// error state happens to persist.
  bool _showingErrorVisual = false;

  /// Index of the digit currently being briefly revealed, or null when none.
  int? _revealedIndex;
  Timer? _revealTimer;

  /// Tracks the length of the PIN as of the last completed [_handleTextChanged]
  /// call. Used to detect digit additions vs removals for the reveal feature.
  int _lastKnownLength = 0;

  String get _pin => _controller.text;
  int get _filledCount => _pin.length;
  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _lastKnownLength = _controller.text.length;
    _controller.addListener(_handleTextChanged);

    if (widget.useNativeKeyboard) {
      _focusNode = FocusNode();
    }

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _previousErrorText = widget.errorText;
    _showingErrorVisual = _hasError;
  }

  @override
  void didUpdateWidget(PicoPinInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _lastKnownLength = _controller.text.length;
      _controller.addListener(_handleTextChanged);
    }

    if (_hasError && _previousErrorText != widget.errorText) {
      // A genuinely new error just arrived — acknowledge it visually once.
      _showingErrorVisual = true;
      _triggerErrorFeedback();
    } else if (!_hasError) {
      // The caller cleared the error directly — honor that immediately
      // rather than waiting for the next keystroke.
      _showingErrorVisual = false;
    }
    _previousErrorText = widget.errorText;
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    // Enforce digit-only and max length when driven by external controller
    // (no TextField formatters in custom keyboard mode).
    final text = _controller.text;
    final digitsOnly = text.replaceAll(RegExp('[^0-9]'), '');
    final clamped = digitsOnly.length > widget.length
        ? digitsOnly.substring(0, widget.length)
        : digitsOnly;

    if (clamped != text) {
      _controller
        ..text = clamped
        ..selection = TextSelection.collapsed(offset: clamped.length);
      return; // Will re-trigger this callback with clean text.
    }

    final previousLength = _lastKnownLength;
    final newLength = clamped.length;

    if (previousLength == 0 && newLength > 0) {
      // First digit of a fresh attempt — reset the error visual even if the
      // caller hasn't cleared errorText yet (it may only clear once the next
      // full submission resolves, not on every keystroke).
      _showingErrorVisual = false;
    }

    if (widget.revealDuration != null) {
      if (newLength > previousLength) {
        // A digit was appended — briefly reveal it.
        _scheduleReveal(newLength - 1);
      } else if (newLength < previousLength) {
        // A digit was removed — cancel any pending reveal.
        _cancelReveal();
      }
    }

    _lastKnownLength = newLength;
    setState(() {});
    widget.onChanged?.call(_pin);
    if (_pin.length == widget.length) {
      widget.onCompleted?.call(_pin);
    }
  }

  void _scheduleReveal(int index) {
    _revealTimer?.cancel();
    _revealedIndex = index;
    _revealTimer = Timer(widget.revealDuration!, () {
      if (mounted) {
        setState(() => _revealedIndex = null);
      }
    });
  }

  void _cancelReveal() {
    _revealTimer?.cancel();
    _revealTimer = null;
    _revealedIndex = null;
  }

  Future<void> _triggerErrorFeedback() async {
    if (widget.enableHapticFeedback) {
      final canVibrate = await Haptics.canVibrate();
      if (canVibrate) {
        await Haptics.vibrate(HapticsType.error);
      }
    }
    if (widget.enableShakeOnError && mounted) {
      _shakeController.reset();
      await _shakeController.forward();
    }
  }

  void _handleTap() {
    if (!widget.enabled || !widget.useNativeKeyboard) return;
    _focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor =
        widget.activeColor ?? context.colors.foreground.main;
    final effectiveInactiveColor =
        widget.inactiveColor ?? context.colors.outline.subtle;
    final effectiveErrorColor =
        widget.errorColor ?? context.colors.foreground.error;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              ),
              child: GestureDetector(
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hidden text field for native keyboard input.
                    if (widget.useNativeKeyboard)
                      Opacity(
                        opacity: 0,
                        child: SizedBox(
                          height: 1,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: widget.autofocus,
                            enabled: widget.enabled,
                            keyboardType: TextInputType.number,
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
                    // Dot indicators
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.length, (index) {
                        final isFilled = index < _filledCount;
                        final isRevealed = isFilled && index == _revealedIndex;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < widget.length - 1
                                ? widget.dotSpacing
                                : 0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: isRevealed
                                ? SizedBox(
                                    key: ValueKey('revealed-$index'),
                                    width: widget.dotSize,
                                    height: widget.dotSize,
                                    child: Center(
                                      child: Text(
                                        _pin[index],
                                        style: context.typography.body.small
                                            .copyWith(
                                              color: _showingErrorVisual
                                                  ? effectiveErrorColor
                                                  : effectiveActiveColor,
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                            ),
                                      ),
                                    ),
                                  )
                                : AnimatedContainer(
                                    key: ValueKey('dot-$index'),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    width: widget.dotSize,
                                    height: widget.dotSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _showingErrorVisual
                                          ? effectiveErrorColor
                                          : isFilled
                                          ? effectiveActiveColor
                                          : effectiveInactiveColor,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasError) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorText!,
                style: context.typography.body.small.copyWith(
                  color: effectiveErrorColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
