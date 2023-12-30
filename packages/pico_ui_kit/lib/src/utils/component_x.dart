import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Extension methods for adding skeleton loading animations to Flutter widgets.
///
/// The `SkeletonExtension` extension provides a convenient way to apply
/// skeleton loading animations to existing Flutter widgets. It adds a
/// `sekeletonize` method to the `Widget` class, allowing users to customize
/// the appearance of skeleton animations by specifying parameters such as
/// `paintingEffect`, `containerColor`, and `ignoreContainer`.
///
/// Example usage:
/// ```dart
/// Widget myWidget = ... // Your Flutter widget.
///
/// Skeletonizer skeletonizedWidget = myWidget.sekeletonize(
///   paintingEffect: PaintingEffect.fromPainters([ShimmeringRectPainter()]),
///   containerColor: Colors.grey[300],
///   ignoreContainer: true,
/// );
/// ```
extension SkeletonExtension on Widget {
  /// Applies skeleton loading animations to the widget using the specified
  /// parameters.
  ///
  /// The [paintingEffect] parameter represents the visual effect of the
  /// skeleton animation.
  ///
  /// The [containerColor] parameter defines the color of the skeleton
  /// containers.
  ///
  /// The [ignoreContainer] parameter determines whether to ignore certain
  /// containers during the animation.
  /// Returns a `Skeletonizer` widget that wraps the original widget and applies
  /// skeleton animations.
  Skeletonizer sekeletonize({
    PaintingEffect? paintingEffect,
    Color? containerColor,
    bool? ignoreContainer,
  }) =>
      Skeletonizer(
        containersColor: containerColor,
        effect: paintingEffect,
        ignoreContainers: ignoreContainer,
        justifyMultiLineText: true,
        textBoneBorderRadius: TextBoneBorderRadius(
          BorderRadius.circular(8.r),
        ),
        child: this,
      );
}
