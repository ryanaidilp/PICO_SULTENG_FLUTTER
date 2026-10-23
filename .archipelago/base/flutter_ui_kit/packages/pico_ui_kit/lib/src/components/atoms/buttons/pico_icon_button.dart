import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/src/components/atoms/buttons/pico_icon_button_config.dart';
import 'package:pico_ui_kit/src/components/atoms/icons/pico_icon.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

export 'package:pico_ui_kit/src/components/atoms/buttons/pico_icon_button_config.dart'
    show PicoIconButtonSize, PicoIconButtonVariant;

/// An icon-only button component following the design system.
///
/// Supports both Flutter [IconData] and design system [PicoIconAsset]:
/// ```dart
/// // Using IconData
/// PicoIconButton(
///   icon: Icons.add,
///   onPressed: () {},
///   variant: PicoIconButtonVariant.filled,
/// )
///
/// // Using PicoIconAsset
/// PicoIconButton.asset(
///   PicoActionsIcons.search,
///   onPressed: () {},
/// )
/// ```
class PicoIconButton extends StatelessWidget {
  /// Creates an [PicoIconButton] with Flutter [IconData].
  const new({
    required IconData this.icon,
    this.onPressed,
    this.variant = PicoIconButtonVariant.standard,
    this.size = PicoIconButtonSize.md,
    this.tooltip,
    this.isLoading = false,
    this.isSelected = false,
    super.key,
  }) : asset = null;

  /// Creates an [PicoIconButton] with design system [PicoIconAsset].
  const new asset(
    PicoIconAsset this.asset, {
    this.onPressed,
    this.variant = PicoIconButtonVariant.standard,
    this.size = PicoIconButtonSize.md,
    this.tooltip,
    this.isLoading = false,
    this.isSelected = false,
    super.key,
  }) : icon = null;

  /// The Flutter icon to display.
  final IconData? icon;

  /// The design system icon asset to display.
  final PicoIconAsset? asset;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The visual variant of the button.
  final PicoIconButtonVariant variant;

  /// The size preset of the button.
  final PicoIconButtonSize size;

  /// Optional tooltip text.
  final String? tooltip;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the button is in selected state.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radius;

    final isEnabled = onPressed != null && !isLoading;
    final borderRadius = size.borderRadius(radius);

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => variant.resolveBackgroundColor(
          states,
          colors,
          isSelected: isSelected,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => variant.resolveForegroundColor(
          states,
          colors,
          isSelected: isSelected,
        ),
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => variant.resolveForegroundColor(
          states,
          colors,
          isSelected: isSelected,
        ),
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
      side: variant.isOutlined
          ? WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color:
                    variant.resolveBorderColor(states, colors) ??
                    Colors.transparent,
              ),
            )
          : null,
      minimumSize: WidgetStatePropertyAll(
        Size(size.buttonSize, size.buttonSize),
      ),
      fixedSize: WidgetStatePropertyAll(Size(size.buttonSize, size.buttonSize)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    final foregroundColor = variant.foregroundColor(
      colors,
      isSelected: isSelected,
    );

    final child = _PicoIconButtonContent(
      icon: icon,
      asset: asset,
      isLoading: isLoading,
      iconSize: size.iconSize,
      loadingColor: foregroundColor,
    );

    final button = IconButton(
      onPressed: isEnabled ? onPressed : null,
      icon: child,
      iconSize: size.iconSize,
      style: buttonStyle,
    );

    if (tooltip case final tooltipText?) {
      return Tooltip(message: tooltipText, child: button);
    }

    return button;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData?>('icon', icon))
      ..add(DiagnosticsProperty<PicoIconAsset?>('asset', asset))
      ..add(EnumProperty<PicoIconButtonVariant>('variant', variant))
      ..add(EnumProperty<PicoIconButtonSize>('size', size))
      ..add(StringProperty('tooltip', tooltip))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<bool>('isSelected', isSelected))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed));
  }
}

/// Default animation duration for icon button state transitions.
const _kIconButtonAnimationDuration = Duration(milliseconds: 200);

/// Internal widget for icon button content with animated transitions.
class const _PicoIconButtonContent({
  required final IconData? icon,
  required final PicoIconAsset? asset,
  required final bool isLoading,
  required final double iconSize,
  required final Color loadingColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final iconWidget = _buildIcon();

    return AnimatedSwitcher(
      duration: _kIconButtonAnimationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          // Invisible icon to maintain size
          Opacity(opacity: 0, child: iconWidget),
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
          : KeyedSubtree(key: const ValueKey('icon'), child: iconWidget),
    );
  }

  Widget _buildIcon() {
    if (icon case final iconData?) {
      return Icon(iconData, size: iconSize);
    }

    if (asset case final iconAsset?) {
      return PicoIcon.asset(iconAsset, size: iconSize);
    }

    return SizedBox.square(dimension: iconSize);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData?>('icon', icon))
      ..add(DiagnosticsProperty<PicoIconAsset?>('asset', asset))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DoubleProperty('iconSize', iconSize))
      ..add(ColorProperty('loadingColor', loadingColor));
  }
}
