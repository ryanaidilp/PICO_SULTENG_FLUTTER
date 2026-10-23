import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A skeleton placeholder widget for loading assets.
///
/// This widget displays an animated shimmer effect while an asset is loading,
/// providing visual feedback to the user.
///
/// Example usage:
/// ```dart
/// PicoAssetSkeleton(
///   width: 100,
///   height: 100,
/// )
/// ```
class PicoAssetSkeleton extends StatelessWidget {
  /// Creates an [PicoAssetSkeleton].
  const new({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  /// Creates a circular skeleton.
  const new circle({super.key, double? size})
    : width = size,
      height = size,
      borderRadius = null,
      shape = BoxShape.circle;

  /// The width of the skeleton.
  final double? width;

  /// The height of the skeleton.
  final double? height;

  /// The border radius of the skeleton.
  final BorderRadius? borderRadius;

  /// The shape of the skeleton.
  final BoxShape shape;

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: Bone(
      width: width,
      height: height,
      borderRadius: shape == BoxShape.circle
          ? BorderRadius.circular((width ?? height ?? 24) / 2)
          : borderRadius ?? BorderRadius.circular(4),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
    properties.add(DoubleProperty('height', height));
    properties.add(
      DiagnosticsProperty<BorderRadius?>('borderRadius', borderRadius),
    );
    properties.add(EnumProperty<BoxShape>('shape', shape));
  }
}
