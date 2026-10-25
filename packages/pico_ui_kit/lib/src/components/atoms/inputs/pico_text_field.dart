import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_text_field_config.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';
import 'package:pico_ui_kit/src/utilities/debouncer.dart';

export 'package:pico_ui_kit/src/components/atoms/inputs/pico_text_field_config.dart'
    show PicoTextFieldSize, PicoTextFieldVariant;

/// A customizable text field with external label following the design system.
///
/// Supports multiple variants, sizes, and validation states with haptic
/// feedback and shake animation on errors.
///
/// ```dart
/// PicoTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   variant: PicoTextFieldVariant.bordered,
/// )
/// ```
class const PicoTextField({
  /// Text editing controller.
  final TextEditingController? controller,

  /// Focus node for the input.
  final FocusNode? focusNode,

  /// External label displayed above the input.
  final String? label,

  /// Placeholder text when input is empty.
  final String? hint,

  /// Helper text displayed below the input.
  final String? helperText,

  /// Error text displayed below the input (overrides helperText).
  final String? errorText,

  /// The visual variant of the input.
  final PicoTextFieldVariant variant = PicoTextFieldVariant.bordered,

  /// The size preset of the input.
  final PicoTextFieldSize size = PicoTextFieldSize.md,

  /// Icon displayed at the start of the input.
  final Widget? prefixIcon,

  /// Icon displayed at the end of the input.
  final Widget? suffixIcon,

  /// Whether to obscure the text (for passwords).
  final bool obscureText = false,

  /// Whether the input is enabled.
  final bool enabled = true,

  /// Whether the input is read-only.
  final bool readOnly = false,

  /// Maximum number of lines.
  final int? maxLines = 1,

  /// Minimum number of lines.
  final int? minLines,

  /// Maximum character length.
  final int? maxLength,

  /// Keyboard type.
  final TextInputType? keyboardType,

  /// Text input action.
  final TextInputAction? textInputAction,

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters,

  /// Callback when text changes.
  final ValueChanged<String>? onChanged,

  /// Callback when submitted.
  final ValueChanged<String>? onSubmitted,

  /// Callback when tapped.
  final VoidCallback? onTap,

  /// Whether to autofocus.
  final bool autofocus = false,

  /// Whether to autocorrect.
  final bool autocorrect = true,

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization = TextCapitalization.none,

  /// Whether the field is required (shows asterisk in label).
  final bool isRequired = false,

  /// Whether to provide haptic feedback on error.
  final bool enableHapticFeedback = true,

  /// Whether to shake the field on error.
  final bool enableShakeOnError = true,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoTextField].
  this;

  @override
  State<PicoTextField> createState() => _PicoTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController?>('controller', controller),
      )
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode))
      ..add(StringProperty('label', label))
      ..add(StringProperty('hint', hint))
      ..add(StringProperty('helperText', helperText))
      ..add(StringProperty('errorText', errorText))
      ..add(EnumProperty<PicoTextFieldVariant>('variant', variant))
      ..add(EnumProperty<PicoTextFieldSize>('size', size))
      ..add(DiagnosticsProperty<bool>('obscureText', obscureText))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<bool>('readOnly', readOnly))
      ..add(IntProperty('maxLines', maxLines))
      ..add(IntProperty('minLines', minLines))
      ..add(IntProperty('maxLength', maxLength))
      ..add(DiagnosticsProperty<TextInputType?>('keyboardType', keyboardType))
      ..add(EnumProperty<TextInputAction?>('textInputAction', textInputAction))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<bool>('autocorrect', autocorrect))
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
        ),
      )
      ..add(DiagnosticsProperty<bool>('isRequired', isRequired))
      ..add(
        DiagnosticsProperty<bool>('enableHapticFeedback', enableHapticFeedback),
      )
      ..add(DiagnosticsProperty<bool>('enableShakeOnError', enableShakeOnError))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
        ),
      );
  }
}

class _PicoTextFieldState()
    extends State<PicoTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isFocused = false;
  String? _previousErrorText;

  /// Debouncer for error feedback to prevent rapid haptic calls.
  final _errorFeedbackDebouncer = Debouncer(milliseconds: 300);

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  PicoTextFieldState get _fieldState {
    if (!widget.enabled) return PicoTextFieldState.disabled;
    if (_hasError) return PicoTextFieldState.error;
    if (_isFocused) return PicoTextFieldState.focused;
    return PicoTextFieldState.normal;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _previousErrorText = widget.errorText;

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
  }

  @override
  void didUpdateWidget(PicoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle focus node change
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }

    // Trigger shake and haptic feedback when error appears
    if (_hasError && _previousErrorText != widget.errorText) {
      _triggerErrorFeedback();
    }
    _previousErrorText = widget.errorText;
  }

  @override
  void dispose() {
    _errorFeedbackDebouncer.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _triggerErrorFeedback() {
    _errorFeedbackDebouncer.run(_executeErrorFeedback);
  }

  Future<void> _executeErrorFeedback() async {
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final radius = context.radius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          // The field itself carries the label (below), so a screen reader
          // announces "label, edit box" instead of a loose text and an
          // unnamed edit box (WCAG 1.3.1, 4.1.2).
          ExcludeSemantics(
            child: _PicoTextFieldLabel(
              label: widget.label!,
              isRequired: widget.isRequired,
              state: _fieldState,
              typography: typography,
              colors: colors,
              spacing: spacing,
            ),
          ),
          SizedBox(height: spacing.xs),
        ],
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
          child: Semantics(
            label: widget.label,
            child: _PicoTextFieldInput(
              controller: widget.controller,
              focusNode: _focusNode,
              hint: widget.hint,
              variant: widget.variant,
              size: widget.size,
              state: _fieldState,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              autofocus: widget.autofocus,
              autocorrect: widget.autocorrect,
              textCapitalization: widget.textCapitalization,
              isFocused: _isFocused,
              spacing: spacing,
              typography: typography,
              colors: colors,
              radius: radius,
            ),
          ),
        ),
        // Animated helper/error text
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _hasError || widget.helperText != null
              ? Padding(
                  padding: EdgeInsets.only(top: spacing.xs),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _PicoTextFieldHelper(
                      key: ValueKey(_hasError ? 'error' : 'helper'),
                      text: _hasError ? widget.errorText! : widget.helperText!,
                      isError: _hasError,
                      typography: typography,
                      colors: colors,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Internal widget for the text field label.
class const _PicoTextFieldLabel({
  required final String label,
  required final bool isRequired,
  required final PicoTextFieldState state,
  required final PicoTypographyExtension typography,
  required final PicoColorExtension colors,
  required final PicoSpacingExtension spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: typography.label.caption.copyWith(
          color: state.labelColor(colors),
          fontWeight: FontWeight.w500,
        ),
      ),
      if (isRequired) ...[
        SizedBox(width: spacing.xxs),
        Text(
          '*',
          style: typography.label.caption.copyWith(
            color: colors.foreground.error,
          ),
        ),
      ],
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<bool>('isRequired', isRequired))
      ..add(EnumProperty<PicoTextFieldState>('state', state))
      ..add(
        DiagnosticsProperty<PicoTypographyExtension>('typography', typography),
      )
      ..add(DiagnosticsProperty<PicoColorExtension>('colors', colors))
      ..add(DiagnosticsProperty<PicoSpacingExtension>('spacing', spacing));
  }
}

/// Internal widget for the text field input.
class const _PicoTextFieldInput({
  required final PicoTextFieldVariant variant,
  required final PicoTextFieldSize size,
  required final PicoTextFieldState state,
  required final bool isFocused,
  required final PicoSpacingExtension spacing,
  required final PicoTypographyExtension typography,
  required final PicoColorExtension colors,
  required final PicoRadiusExtension radius,
  final TextEditingController? controller,
  final FocusNode? focusNode,
  final String? hint,
  final Widget? prefixIcon,
  final Widget? suffixIcon,
  final bool obscureText = false,
  final bool enabled = true,
  final bool readOnly = false,
  final int? maxLines = 1,
  final int? minLines,
  final int? maxLength,
  final TextInputType? keyboardType,
  final TextInputAction? textInputAction,
  final List<TextInputFormatter>? inputFormatters,
  final ValueChanged<String>? onChanged,
  final ValueChanged<String>? onSubmitted,
  final VoidCallback? onTap,
  final bool autofocus = false,
  final bool autocorrect = true,
  final TextCapitalization textCapitalization = TextCapitalization.none,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textStyle = size
        .textStyle(typography)
        .copyWith(color: state.textColor(colors));

    final showFill = !variant.showFillOnFocusOnly || isFocused;

    return SizedBox(
      height: size.height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textStyle.copyWith(color: colors.foreground.muted),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: size.contentPadding(spacing),
          filled: showFill,
          fillColor: state.fillColor(colors, isEnabled: enabled),
          border: variant.resolveBorder(
            radius: radius,
            color: state.borderColor(colors),
            isFocused: isFocused,
          ),
          enabledBorder: variant.resolveBorder(
            radius: radius,
            color: state == PicoTextFieldState.error
                ? PicoTextFieldState.error.borderColor(colors)
                : PicoTextFieldState.normal.borderColor(colors),
            isFocused: false,
          ),
          focusedBorder: variant.resolveBorder(
            radius: radius,
            color: state == PicoTextFieldState.error
                ? PicoTextFieldState.error.borderColor(colors)
                : PicoTextFieldState.focused.borderColor(colors),
            isFocused: true,
          ),
          errorBorder: variant.resolveBorder(
            radius: radius,
            color: PicoTextFieldState.error.borderColor(colors),
            isFocused: false,
          ),
          focusedErrorBorder: variant.resolveBorder(
            radius: radius,
            color: PicoTextFieldState.error.borderColor(colors),
            isFocused: true,
          ),
          disabledBorder: variant.resolveBorder(
            radius: radius,
            color: PicoTextFieldState.disabled.borderColor(colors),
            isFocused: false,
          ),
          counterText: '',
        ),
        obscureText: obscureText,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        autofocus: autofocus,
        autocorrect: autocorrect,
        textCapitalization: textCapitalization,
        style: textStyle,
        cursorColor: colors.action.primary.active,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController?>('controller', controller),
      )
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode))
      ..add(StringProperty('hint', hint))
      ..add(EnumProperty<PicoTextFieldVariant>('variant', variant))
      ..add(EnumProperty<PicoTextFieldSize>('size', size))
      ..add(EnumProperty<PicoTextFieldState>('state', state))
      ..add(DiagnosticsProperty<bool>('isFocused', isFocused))
      ..add(DiagnosticsProperty<bool>('obscureText', obscureText))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<bool>('readOnly', readOnly))
      ..add(IntProperty('maxLines', maxLines))
      ..add(IntProperty('minLines', minLines))
      ..add(IntProperty('maxLength', maxLength))
      ..add(DiagnosticsProperty<TextInputType?>('keyboardType', keyboardType))
      ..add(EnumProperty<TextInputAction?>('textInputAction', textInputAction))
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
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
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<bool>('autocorrect', autocorrect))
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
        ),
      )
      ..add(DiagnosticsProperty<PicoSpacingExtension>('spacing', spacing))
      ..add(
        DiagnosticsProperty<PicoTypographyExtension>('typography', typography),
      )
      ..add(DiagnosticsProperty<PicoColorExtension>('colors', colors))
      ..add(DiagnosticsProperty<PicoRadiusExtension>('radius', radius));
  }
}

/// Internal widget for helper/error text.
class const _PicoTextFieldHelper({
  required final String text,
  required final bool isError,
  required final PicoTypographyExtension typography,
  required final PicoColorExtension colors,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: typography.label.caption.copyWith(
      color: isError ? colors.foreground.error : colors.foreground.subtle,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(DiagnosticsProperty<bool>('isError', isError))
      ..add(
        DiagnosticsProperty<PicoTypographyExtension>('typography', typography),
      )
      ..add(DiagnosticsProperty<PicoColorExtension>('colors', colors));
  }
}
