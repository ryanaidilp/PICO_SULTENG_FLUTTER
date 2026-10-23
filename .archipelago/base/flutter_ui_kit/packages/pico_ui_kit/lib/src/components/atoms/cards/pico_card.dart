import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/cards/pico_card_config.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

export 'package:pico_ui_kit/src/components/atoms/cards/pico_card_config.dart'
    show PicoCardSize, PicoCardVariant;

/// A customizable card component following the design system.
///
/// Supports multiple variants, sizes, and optional tap interaction.
///
/// ```dart
/// PicoCard(
///   child: Text('Card content'),
///   variant: PicoCardVariant.elevated,
///   size: PicoCardSize.md,
/// )
/// ```
class const PicoCard({
  /// The card content.
  required final Widget child,

  /// The visual variant of the card.
  final PicoCardVariant variant = PicoCardVariant.elevated,

  /// The size preset of the card.
  final PicoCardSize size = PicoCardSize.md,

  /// Callback when the card is tapped.
  final VoidCallback? onTap,

  /// Custom padding for the card content (overrides size preset).
  final EdgeInsetsGeometry? padding,

  /// Custom margin around the card.
  final EdgeInsetsGeometry? margin,

  /// Custom width for the card.
  final double? width,

  /// Custom height for the card.
  final double? height,

  /// Custom border radius for the card (overrides size preset).
  final BorderRadiusGeometry? borderRadius,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoCard].
  this;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;
    final shadow = context.shadow;
    final colors = context.colors;

    final effectivePadding = padding ?? size.padding(spacing);
    final effectiveRadius = borderRadius ?? size.borderRadius(radius);
    final decoration = variant.decoration(colors, shadow, effectiveRadius);

    final cardContent = _PicoCardContent(
      width: width,
      height: height,
      margin: margin,
      decoration: decoration,
      padding: effectivePadding,
      child: child,
    );

    if (onTap == null) {
      return cardContent;
    }

    return _TappableCard(
      onTap: onTap!,
      borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : null,
      child: cardContent,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<PicoCardVariant>('variant', variant))
      ..add(EnumProperty<PicoCardSize>('size', size))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('margin', margin))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height))
      ..add(
        DiagnosticsProperty<BorderRadiusGeometry?>(
          'borderRadius',
          borderRadius,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
}

/// Internal widget for card content layout.
class const _PicoCardContent({
  required final BoxDecoration decoration,
  required final EdgeInsetsGeometry padding,
  required final Widget child,
  final double? width,
  final double? height,
  final EdgeInsetsGeometry? margin,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    margin: margin,
    decoration: decoration,
    child: Padding(padding: padding, child: child),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('margin', margin))
      ..add(DiagnosticsProperty<BoxDecoration>('decoration', decoration))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

/// Internal widget for tappable card wrapper.
class const _TappableCard({
  required final VoidCallback onTap,
  required final Widget child,
  final BorderRadius? borderRadius,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(DiagnosticsProperty<BorderRadius?>('borderRadius', borderRadius));
  }
}
