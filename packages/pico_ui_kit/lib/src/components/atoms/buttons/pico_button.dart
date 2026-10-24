import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:pico_ui_kit/src/components/atoms/buttons/pico_button_config.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';

export 'package:pico_ui_kit/src/components/atoms/buttons/pico_button_config.dart'
    show PicoButtonColor, PicoButtonSize, PicoButtonStyle;

/// A customizable button component following the design system.
///
/// Supports multiple styles, color variants, sizes, states, debounce,
/// and haptic feedback on press.
///
/// ```dart
/// PicoButton(
///   label: 'Submit',
///   onPressed: () {},
///   style: PicoButtonStyle.filled,
///   color: PicoButtonColor.primary,
///   size: PicoButtonSize.md,
///   debounceDuration: Duration(milliseconds: 300),
/// )
/// ```
class const PicoButton({
  /// The button label text.
  required final String label,

  /// Callback when the button is pressed.
  final VoidCallback? onPressed,

  /// The visual style of the button (filled, outlined, text, ghost).
  final PicoButtonStyle style = PicoButtonStyle.filled,

  /// The color variant of the button (primary, secondary, destructive, success).
  final PicoButtonColor color = PicoButtonColor.primary,

  /// The size preset of the button.
  final PicoButtonSize size = PicoButtonSize.md,

  /// Optional icon displayed before the label.
  final IconData? leadingIcon,

  /// Optional icon displayed after the label.
  final IconData? trailingIcon,

  /// Whether to show a loading indicator.
  final bool isLoading = false,

  /// Whether the button should expand to fill available width.
  final bool isExpanded = false,

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback = true,

  /// Duration to debounce rapid button presses.
  ///
  /// Set to [Duration.zero] to disable debouncing.
  final Duration debounceDuration = const Duration(milliseconds: 300),
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoButton].
  this;

  @override
  State<PicoButton> createState() => _PicoButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<PicoButtonStyle>('style', style))
      ..add(EnumProperty<PicoButtonColor>('color', color))
      ..add(EnumProperty<PicoButtonSize>('size', size))
      ..add(DiagnosticsProperty<IconData?>('leadingIcon', leadingIcon))
      ..add(DiagnosticsProperty<IconData?>('trailingIcon', trailingIcon))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<bool>('isExpanded', isExpanded))
      ..add(
        DiagnosticsProperty<bool>('enableHapticFeedback', enableHapticFeedback),
      )
      ..add(DiagnosticsProperty<Duration>('debounceDuration', debounceDuration))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed));
  }
}

class _PicoButtonState() extends State<PicoButton> {
  Timer? _debounceTimer;
  bool _isDebouncing = false;

  bool get _isEnabled =>
      widget.onPressed != null && !widget.isLoading && !_isDebouncing;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (!_isEnabled) return;

    if (widget.enableHapticFeedback) {
      // Haptics are a nicety: a missing plugin (tests, desktop) or a vibrator
      // error must never swallow the press.
      try {
        if (await Haptics.canVibrate()) {
          await Haptics.vibrate(HapticsType.light);
        }
      } on Object {
        // ignore: the press still goes through
      }
    }

    widget.onPressed?.call();

    if (widget.debounceDuration > Duration.zero) {
      setState(() => _isDebouncing = true);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (mounted) {
          setState(() => _isDebouncing = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;
    final typography = context.typography;

    final buttonStyle = _buildButtonStyle(colors, spacing, radius);
    final textStyle = widget.size.textStyle(typography);

    final child = _PicoButtonContent(
      isLoading: widget.isLoading,
      leadingIcon: widget.leadingIcon,
      trailingIcon: widget.trailingIcon,
      label: widget.label,
      textStyle: textStyle,
      iconSize: widget.size.iconSize,
      loadingColor: widget.style.foregroundColor(colors, widget.color),
      spacing: spacing,
    );

    final button = switch (widget.style) {
      PicoButtonStyle.filled => FilledButton(
        onPressed: _isEnabled ? _handlePressed : null,
        style: buttonStyle,
        child: child,
      ),
      PicoButtonStyle.outlined => OutlinedButton(
        onPressed: _isEnabled ? _handlePressed : null,
        style: buttonStyle,
        child: child,
      ),
      PicoButtonStyle.text || PicoButtonStyle.ghost => TextButton(
        onPressed: _isEnabled ? _handlePressed : null,
        style: buttonStyle,
        child: child,
      ),
    };

    if (widget.isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  ButtonStyle _buildButtonStyle(
    PicoColorExtension colors,
    PicoSpacingExtension spacing,
    PicoRadiusExtension radius,
  ) {
    final borderRadius = widget.size.borderRadius(radius);

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            widget.style.resolveBackgroundColor(states, colors, widget.color),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            widget.style.resolveForegroundColor(states, colors, widget.color),
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) =>
            widget.style.resolveForegroundColor(states, colors, widget.color),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.action.primary.active.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return colors.action.primary.active.withValues(alpha: 0.05);
        }
        return Colors.transparent;
      }),
      side: widget.style.isOutlined
          ? WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color:
                    widget.style.resolveBorderColor(
                      states,
                      colors,
                      widget.color,
                    ) ??
                    Colors.transparent,
              ),
            )
          : null,
      padding: WidgetStatePropertyAll(widget.size.padding(spacing)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      minimumSize: WidgetStatePropertyAll(Size(0, widget.size.minHeight)),
      alignment: Alignment.center,
    );
  }
}

/// Default animation duration for button state transitions.
const _kButtonAnimationDuration = Duration(milliseconds: 200);

/// Internal widget for button content with animated transitions.
class const _PicoButtonContent({
  required final bool isLoading,
  required final String label,
  required final TextStyle textStyle,
  required final double iconSize,
  required final Color loadingColor,
  required final PicoSpacingExtension spacing,
  final IconData? leadingIcon,
  final IconData? trailingIcon,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    return AnimatedSwitcher(
      duration: _kButtonAnimationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          // Invisible content to maintain size
          Opacity(opacity: 0, child: content),
          // Previous children (animating out)
          ...previousChildren,
          // Current child (animating in)
          ?currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: iconSize,
              width: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
              ),
            )
          : KeyedSubtree(key: const ValueKey('content'), child: content),
    );
  }

  Widget _buildContent() {
    final hasLeading = leadingIcon != null;
    final hasTrailing = trailingIcon != null;

    if (!hasLeading && !hasTrailing) {
      return Text(label, style: textStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasLeading) ...[
          Icon(leadingIcon, size: iconSize),
          SizedBox(width: spacing.sm),
        ],
        Text(label, style: textStyle),
        if (hasTrailing) ...[
          SizedBox(width: spacing.sm),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<TextStyle>('textStyle', textStyle))
      ..add(DoubleProperty('iconSize', iconSize))
      ..add(ColorProperty('loadingColor', loadingColor))
      ..add(DiagnosticsProperty<PicoSpacingExtension>('spacing', spacing))
      ..add(DiagnosticsProperty<IconData?>('leadingIcon', leadingIcon))
      ..add(DiagnosticsProperty<IconData?>('trailingIcon', trailingIcon));
  }
}
