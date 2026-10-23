import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/src/components/atoms/assets/pico_asset_widget.dart';

/// A unified icon widget that renders either Flutter [IconData] or
/// [PicoIconAsset] from the design system.
///
/// This provides a consistent API for rendering icons regardless of source:
/// ```dart
/// // Using Flutter IconData
/// PicoIcon(icon: Icons.search, size: 24)
///
/// // Using design system asset
/// PicoIcon(asset: PicoActionsIcons.search, size: 24)
///
/// // Named constructors for clarity
/// PicoIcon.data(Icons.search, size: 24)
/// PicoIcon.asset(PicoActionsIcons.search, size: 24)
/// ```
class PicoIcon extends StatelessWidget {
  /// Creates an [PicoIcon] with either [icon] or [asset].
  ///
  /// Exactly one of [icon] or [asset] must be provided.
  const new({
    this.icon,
    this.asset,
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  }) : assert(
         (icon != null) != (asset != null),
         'Exactly one of icon or asset must be provided',
       );

  /// Creates an [PicoIcon] from Flutter [IconData].
  const new data(
    IconData this.icon, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  }) : asset = null;

  /// Creates an [PicoIcon] from design system [PicoIconAsset].
  const new asset(
    PicoIconAsset this.asset, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  }) : icon = null;

  /// The Flutter icon data to display.
  final IconData? icon;

  /// The design system icon asset to display.
  final PicoIconAsset? asset;

  /// The size of the icon (width and height).
  final double size;

  /// The color to apply to the icon.
  final Color? color;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (icon case final iconData?) {
      return Icon(
        iconData,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    if (asset case final iconAsset?) {
      return PicoAssetWidget.icon(
        iconAsset,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    // This should never happen due to assertion
    return SizedBox.square(dimension: size);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData?>('icon', icon))
      ..add(DiagnosticsProperty<PicoIconAsset?>('asset', asset))
      ..add(DoubleProperty('size', size))
      ..add(ColorProperty('color', color))
      ..add(StringProperty('semanticLabel', semanticLabel));
  }
}
