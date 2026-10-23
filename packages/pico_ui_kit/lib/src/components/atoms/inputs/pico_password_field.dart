import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/src/components/atoms/icons/pico_icon.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_password_field_config.dart';
import 'package:pico_ui_kit/src/components/atoms/inputs/pico_text_field.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';

export 'package:pico_ui_kit/src/components/atoms/inputs/pico_password_field_config.dart'
    show PasswordStrength;

/// A password input field with visibility toggle and optional strength
/// indicator.
///
/// This component wraps [PicoTextField] with password-specific functionality:
/// - Visibility toggle button to show/hide password
/// - Optional password strength indicator with animated progress bar
/// - Customizable strength calculation
///
/// ```dart
/// PicoPasswordField(
///   label: 'Password',
///   hint: 'Enter your password',
///   showStrengthIndicator: true,
///   onStrengthChanged: (strength) => print('Strength: $strength'),
/// )
/// ```
class const PicoPasswordField({
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

  /// Whether the input is enabled.
  final bool enabled = true,

  /// Whether the input is read-only.
  final bool readOnly = false,

  /// Text input action.
  final TextInputAction? textInputAction,

  /// Callback when text changes.
  final ValueChanged<String>? onChanged,

  /// Callback when submitted.
  final ValueChanged<String>? onSubmitted,

  /// Callback when tapped.
  final VoidCallback? onTap,

  /// Whether to autofocus.
  final bool autofocus = false,

  /// Whether the field is required (shows asterisk in label).
  final bool isRequired = false,

  /// Whether to provide haptic feedback on error.
  final bool enableHapticFeedback = true,

  /// Whether to shake the field on error.
  final bool enableShakeOnError = true,

  /// Whether to show the password strength indicator.
  final bool showStrengthIndicator = false,

  /// Custom strength calculator. If null, uses default algorithm.
  final PasswordStrength Function(String password)? strengthCalculator,

  /// Callback when password strength changes.
  final ValueChanged<PasswordStrength>? onStrengthChanged,

  /// Custom color for the visibility toggle icon.
  final Color? visibilityIconColor,

  /// Whether the password is initially obscured.
  final bool initiallyObscured = true,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoPasswordField].
  this;

  @override
  State<PicoPasswordField> createState() => _PicoPasswordFieldState();

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
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(DiagnosticsProperty<bool>('readOnly', readOnly))
      ..add(EnumProperty<TextInputAction?>('textInputAction', textInputAction))
      ..add(DiagnosticsProperty<bool>('autofocus', autofocus))
      ..add(DiagnosticsProperty<bool>('isRequired', isRequired))
      ..add(
        DiagnosticsProperty<bool>('enableHapticFeedback', enableHapticFeedback),
      )
      ..add(DiagnosticsProperty<bool>('enableShakeOnError', enableShakeOnError))
      ..add(
        DiagnosticsProperty<bool>(
          'showStrengthIndicator',
          showStrengthIndicator,
        ),
      )
      ..add(DiagnosticsProperty<bool>('initiallyObscured', initiallyObscured))
      ..add(ColorProperty('visibilityIconColor', visibilityIconColor))
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
        ObjectFlagProperty<PasswordStrength Function(String)?>.has(
          'strengthCalculator',
          strengthCalculator,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<PasswordStrength>?>.has(
          'onStrengthChanged',
          onStrengthChanged,
        ),
      );
  }
}

class _PicoPasswordFieldState() extends State<PicoPasswordField> {
  late TextEditingController _controller;
  late bool _obscureText;
  PasswordStrength _strength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.initiallyObscured;

    // Calculate initial strength if there's existing text
    if (_controller.text.isNotEmpty) {
      _updateStrength(_controller.text);
    }
  }

  @override
  void didUpdateWidget(PicoPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  void _handleChanged(String value) {
    if (widget.showStrengthIndicator) {
      _updateStrength(value);
    }
    widget.onChanged?.call(value);
  }

  void _updateStrength(String password) {
    final newStrength =
        widget.strengthCalculator?.call(password) ??
        _calculateDefaultStrength(password);

    if (newStrength != _strength) {
      setState(() => _strength = newStrength);
      widget.onStrengthChanged?.call(newStrength);
    }
  }

  /// Default password strength calculation algorithm.
  PasswordStrength _calculateDefaultStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    var score = 0;

    // Length checks
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (RegExp('[a-z]').hasMatch(password)) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Map score to strength
    return switch (score) {
      0 || 1 => PasswordStrength.weak,
      2 || 3 => PasswordStrength.fair,
      4 || 5 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PicoTextField(
          controller: _controller,
          focusNode: widget.focusNode,
          label: widget.label,
          hint: widget.hint,
          helperText: widget.showStrengthIndicator ? null : widget.helperText,
          errorText: widget.errorText,
          variant: widget.variant,
          size: widget.size,
          prefixIcon: widget.prefixIcon,
          suffixIcon: _VisibilityToggle(
            isObscured: _obscureText,
            onToggle: _toggleVisibility,
            iconColor: widget.visibilityIconColor ?? colors.foreground.muted,
            enabled: widget.enabled,
            size: widget.size,
          ),
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          inputFormatters: [
            // Prevent whitespace in passwords
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          onChanged: _handleChanged,
          onSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          autocorrect: false,
          isRequired: widget.isRequired,
          enableHapticFeedback: widget.enableHapticFeedback,
          enableShakeOnError: widget.enableShakeOnError,
        ),
        if (widget.showStrengthIndicator) ...[
          SizedBox(height: spacing.xs),
          _PasswordStrengthIndicator(
            strength: _strength,
            colors: colors,
            spacing: spacing,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

/// Internal widget for the visibility toggle button.
class const _VisibilityToggle({
  required final bool isObscured,
  required final VoidCallback onToggle,
  required final Color iconColor,
  required final bool enabled,
  required final PicoTextFieldSize size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: PicoIcon.asset(
        isObscured ? PicoActionsIcons.eye : PicoActionsIcons.eyeOff,
        key: ValueKey(isObscured),
        size: size.iconSize,
        color: enabled ? iconColor : iconColor.withValues(alpha: 0.5),
      ),
    ),
    onPressed: enabled ? onToggle : null,
    splashRadius: size.iconSize,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isObscured', isObscured))
      ..add(ColorProperty('iconColor', iconColor))
      ..add(DiagnosticsProperty<bool>('enabled', enabled))
      ..add(EnumProperty<PicoTextFieldSize>('size', size))
      ..add(ObjectFlagProperty<VoidCallback>.has('onToggle', onToggle));
  }
}

/// Internal widget for the password strength indicator.
class const _PasswordStrengthIndicator({
  required final PasswordStrength strength,
  required final PicoColorExtension colors,
  required final PicoSpacingExtension spacing,
  required final PicoTypographyExtension typography,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Progress bar
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 4,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                // Background
                Container(
                  width: constraints.maxWidth,
                  color: colors.background.subtle,
                ),
                // Progress
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * strength.progress,
                  decoration: BoxDecoration(
                    color: strength.color(colors),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Label
      if (strength != PasswordStrength.none) ...[
        SizedBox(height: spacing.xxs),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            strength.label,
            key: ValueKey(strength),
            style: typography.label.caption.copyWith(
              color: strength.color(colors),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<PasswordStrength>('strength', strength))
      ..add(DiagnosticsProperty<PicoColorExtension>('colors', colors))
      ..add(DiagnosticsProperty<PicoSpacingExtension>('spacing', spacing))
      ..add(
        DiagnosticsProperty<PicoTypographyExtension>('typography', typography),
      );
  }
}
