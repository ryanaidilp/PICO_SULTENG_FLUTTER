import 'package:asset_core/asset_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_ui_kit/src/components/atoms/assets/pico_asset_error_widget.dart';
import 'package:pico_ui_kit/src/components/atoms/assets/pico_asset_skeleton.dart';

/// Signature for a function that builds an error widget.
typedef AssetErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Signature for a function that builds a loading widget.
typedef AssetLoadingBuilder = Widget Function(
  BuildContext context,
  double? width,
  double? height,
);

/// A unified widget for rendering all asset types.
///
/// Automatically detects the asset type and uses the appropriate
/// rendering widget:
/// - SVG: `SvgPicture.asset()`
/// - Lottie: `Lottie.asset()`
/// - Raster: `Image.asset()`
///
/// Example:
/// ```dart
/// PicoAssetWidget(PicoActionIcons.search, size: 24)
/// PicoAssetWidget(PicoLogos.appLogo, height: 40)
/// PicoAssetWidget(PicoAnimations.loading, size: 100)
/// ```
class const PicoAssetWidget(
  /// The asset to render.
  final PicoAsset asset, {

  /// Uniform size (sets both width and height).
  final double? size,

  /// Width of the asset.
  final double? width,

  /// Height of the asset.
  final double? height,

  /// Color to tint the asset (for SVG and raster with colorOverride).
  final Color? color,

  /// How the asset should be inscribed into the space.
  final BoxFit fit = BoxFit.contain,

  /// Whether Lottie animations should repeat.
  final bool repeat = true,

  /// Whether animations should auto-play.
  final bool animate = true,

  /// Semantic label for accessibility.
  final String? semanticLabel,

  /// Whether to exclude this asset from the semantics tree.
  ///
  /// Useful when the asset is purely decorative.
  final bool excludeFromSemantics = false,

  /// Custom error widget builder.
  ///
  /// Called when the asset fails to load.
  final AssetErrorBuilder? errorBuilder,

  /// Custom loading widget builder.
  ///
  /// Called while the asset is loading (for Lottie).
  final AssetLoadingBuilder? loadingBuilder,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoAssetWidget].
  this;

  /// Creates an [PicoAssetWidget] for icon assets.
  ///
  /// Icons are typically small, colorable SVG graphics.
  ///
  /// Example:
  /// ```dart
  /// PicoAssetWidget.icon(PicoActionsIcons.search, size: 24, color: Colors.blue)
  /// ```
  const new icon(
    PicoIconAsset icon, {
    double size = 24,
    Color? color,
    BoxFit fit = BoxFit.contain,
    String? semanticLabel,
    Key? key,
  }) : this(
         icon,
         size: size,
         color: color,
         fit: fit,
         semanticLabel: semanticLabel,
         key: key,
       );

  /// Creates an [PicoAssetWidget] for illustration assets.
  ///
  /// Illustrations are larger decorative graphics that may have theme variants.
  ///
  /// Example:
  /// ```dart
  /// PicoAssetWidget.illustration(PicoIllustrations.emptyState, width: 200)
  /// ```
  const new illustration(
    PicoIllustrationAsset illustration, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    String? semanticLabel,
    Key? key,
  }) : this(
         illustration,
         width: width,
         height: height,
         fit: fit,
         semanticLabel: semanticLabel,
         key: key,
       );

  /// Creates an [PicoAssetWidget] for animation assets.
  ///
  /// Supports Lottie `.json` and `.lottie` (dotLottie zip) animations.
  ///
  /// Example:
  /// ```dart
  /// PicoAssetWidget.animation(PicoAnimations.loading, size: 100)
  /// PicoAssetWidget.animation(PicoAnimations.success, repeat: false)
  /// ```
  factory animation(
    PicoAnimationAsset animation, {
    double? size,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool? repeat,
    bool? animate,
    Key? key,
  }) => PicoAssetWidget(
    animation,
    size: size,
    width: width,
    height: height,
    fit: fit,
    repeat: repeat ?? animation.shouldRepeat,
    animate: animate ?? animation.shouldAutoPlay,
    key: key,
  );

  /// Creates an [PicoAssetWidget] for logo assets.
  ///
  /// Logos are brand assets that often have theme variants.
  ///
  /// Example:
  /// ```dart
  /// PicoAssetWidget.logo(PicoLogos.appLogo, height: 40)
  /// ```
  const new logo(
    PicoLogoAsset logo, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    String? semanticLabel,
    Key? key,
  }) : this(
         logo,
         width: width,
         height: height,
         fit: fit,
         semanticLabel: semanticLabel,
         key: key,
       );

  @override
  Widget build(BuildContext context) {
    final data = asset.data;
    final resolvedPath = _resolvePath(context, data);
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final effectiveSemanticLabel = semanticLabel ?? asset.defaultSemanticLabel;

    Widget child = switch (data.type) {
      PicoAssetType.svg => SvgPicture.asset(
        resolvedPath,
        package: data.packageName,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        colorFilter: color != null && data.colorOverride
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        semanticsLabel: excludeFromSemantics ? null : effectiveSemanticLabel,
        placeholderBuilder: loadingBuilder != null
            ? (_) => loadingBuilder!(context, effectiveWidth, effectiveHeight)
            : _defaultLoadingBuilder(effectiveWidth, effectiveHeight),
      ),
      PicoAssetType.lottie => Lottie.asset(
        resolvedPath,
        package: data.packageName,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        repeat: repeat,
        animate: animate,
        errorBuilder: errorBuilder != null
            ? (context, error, stackTrace) =>
                  errorBuilder!(context, error, stackTrace)
            : _defaultErrorBuilder(effectiveWidth, effectiveHeight),
        frameBuilder: (context, child, composition) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: composition != null
              ? child
              : loadingBuilder?.call(
                      context,
                      effectiveWidth,
                      effectiveHeight,
                    ) ??
                    PicoAssetSkeleton(
                      width: effectiveWidth,
                      height: effectiveHeight,
                    ),
        ),
      ),
      PicoAssetType.raster => Image.asset(
        resolvedPath,
        package: data.packageName,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        color: color,
        semanticLabel: excludeFromSemantics ? null : effectiveSemanticLabel,
        errorBuilder: errorBuilder != null
            ? (context, error, stackTrace) =>
                  errorBuilder!(context, error, stackTrace)
            : _defaultErrorBuilder(effectiveWidth, effectiveHeight),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame != null
                ? child
                : loadingBuilder?.call(
                        context,
                        effectiveWidth,
                        effectiveHeight,
                      ) ??
                      PicoAssetSkeleton(
                        width: effectiveWidth,
                        height: effectiveHeight,
                      ),
          );
        },
      ),
    };

    // Wrap with Semantics for animation types (which handle their own)
    if (!excludeFromSemantics && (data.type == PicoAssetType.lottie)) {
      child = Semantics(
        label: effectiveSemanticLabel,
        image: true,
        child: child,
      );
    }

    return child;
  }

  Widget Function(BuildContext) _defaultLoadingBuilder(
    double? width,
    double? height,
  ) =>
      (_) => PicoAssetSkeleton(width: width, height: height);

  Widget Function(BuildContext, Object, StackTrace?) _defaultErrorBuilder(
    double? width,
    double? height,
  ) =>
      (context, error, stackTrace) =>
          PicoAssetErrorWidget(width: width, height: height);

  /// Resolves the correct path based on theme brightness.
  ///
  /// Uses [Theme.of(context).brightness] to properly respond to in-app
  /// theme changes, not just platform/system brightness.
  String _resolvePath(BuildContext context, PicoAssetData data) {
    if (data.darkPath == null) return data.path;

    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? data.darkPath! : data.path;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PicoAsset>('asset', asset));
    properties.add(DoubleProperty('size', size));
    properties.add(DoubleProperty('width', width));
    properties.add(DoubleProperty('height', height));
    properties.add(ColorProperty('color', color));
    properties.add(EnumProperty<BoxFit>('fit', fit));
    properties.add(DiagnosticsProperty<bool>('repeat', repeat));
    properties.add(DiagnosticsProperty<bool>('animate', animate));
    properties.add(StringProperty('semanticLabel', semanticLabel));
    properties.add(
      DiagnosticsProperty<bool>('excludeFromSemantics', excludeFromSemantics),
    );
    properties.add(
      ObjectFlagProperty<AssetErrorBuilder?>.has('errorBuilder', errorBuilder),
    );
    properties.add(
      ObjectFlagProperty<AssetLoadingBuilder?>.has(
        'loadingBuilder',
        loadingBuilder,
      ),
    );
  }
}
