import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A widget displayed when an asset fails to load.
///
/// This widget provides a visual indication that an asset could not be
/// loaded, with an optional retry callback.
///
/// Example usage:
/// ```dart
/// PicoAssetErrorWidget(
///   width: 100,
///   height: 100,
///   onRetry: () => setState(() {}),
/// )
/// ```
class const PicoAssetErrorWidget({
  super.key,

  /// The width of the error widget.
  final double? width,

  /// The height of the error widget.
  final double? height,

  /// The color of the error icon.
  final Color? color,

  /// Called when the user taps to retry loading.
  final VoidCallback? onRetry,

  /// Semantic label for accessibility.
  final String? semanticLabel,
}) extends StatelessWidget {
  /// Creates an [PicoAssetErrorWidget].
  this;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF9E9E9E);

    Widget child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          const IconData(0xe5c9, fontFamily: 'MaterialIcons'),
          size: _calculateIconSize(),
          color: effectiveColor.withValues(alpha: 0.5),
        ),
      ),
    );

    if (onRetry != null) {
      child = GestureDetector(
        onTap: onRetry,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return Semantics(
      label: semanticLabel ?? 'Failed to load asset',
      button: onRetry != null,
      child: child,
    );
  }

  double _calculateIconSize() {
    if (width == null && height == null) return 24;
    final size = (width ?? height ?? 24) * 0.5;
    return size.clamp(16.0, 48.0);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
    properties.add(DoubleProperty('height', height));
    properties.add(ColorProperty('color', color));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onRetry', onRetry));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }
}
