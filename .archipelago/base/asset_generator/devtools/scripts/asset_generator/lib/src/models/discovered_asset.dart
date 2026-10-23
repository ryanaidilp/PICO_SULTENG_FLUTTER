import 'package:path/path.dart' as p;

/// Represents an asset discovered during directory scanning.
class DiscoveredAsset({
  /// The relative path to the asset from package root.
  required final String path,

  /// The type of asset.
  required final AssetType type,

  /// The category of asset.
  required final AssetCategory category,

  /// The path to the dark theme variant, if any.
  final String? darkPath,

  /// Whether this asset supports color override.
  final bool colorOverride = false,
}) {
  /// Creates a new [DiscoveredAsset].
  this;

  /// The enum value name derived from the filename.
  String get enumName {
    final filename = p.basenameWithoutExtension(path);
    return _toEnumName(filename);
  }

  /// Whether this asset has a theme variant.
  bool get hasThemeVariant => darkPath != null;

  static String _toEnumName(String filename) {
    final name = filename
        .replaceAll(RegExp(r'_(light|dark|white|color)$'), '')
        .replaceAll(RegExp('^[0-9]+_'), '');

    final parts = name.split(RegExp(r'[_\-\s]+'));
    if (parts.isEmpty) return name;

    final buffer = StringBuffer(parts.first.toLowerCase());
    for (var i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        buffer.write(parts[i][0].toUpperCase());
        buffer.write(parts[i].substring(1).toLowerCase());
      }
    }

    return buffer.toString();
  }

  @override
  String toString() =>
      'DiscoveredAsset(path: $path, type: $type, category: $category)';
}

/// The type of asset.
enum AssetType() {
  /// SVG vector image.
  svg,

  /// Lottie animation (`.json`, or a `.lottie` dotLottie zip).
  lottie,

  /// Rive animation.
  rive,

  /// Raster image (PNG, JPG, WEBP, GIF).
  raster;

  /// Get the asset type from a file extension.
  static AssetType? fromExtension(String ext) {
    final lower = ext.toLowerCase();
    return switch (lower) {
      '.svg' => AssetType.svg,
      '.json' || '.lottie' => AssetType.lottie,
      '.riv' => AssetType.rive,
      '.png' || '.jpg' || '.jpeg' || '.webp' || '.gif' => AssetType.raster,
      _ => null,
    };
  }
}

/// The category of asset.
enum AssetCategory() {
  /// Icons.
  icon,

  /// Illustrations.
  illustration,

  /// Animations.
  animation,

  /// Logos.
  logo,
}

/// A group of assets by category.
class AssetGroup({
  /// The name of the group.
  required final String name,

  /// The category of assets in this group.
  required final AssetCategory category,

  /// The directory this group was scanned from, relative to the package
  /// root (e.g. `assets/icons/actions`, `assets/animations`).
  ///
  /// Used both as the `// Generated from:` doc comment and as the
  /// `_basePath` constant in the generated enum.
  required final String sourceDir,

  /// The optional subcategory.
  final String? subcategory,
  List<DiscoveredAsset>? assets,
}) {
  /// Creates a new [AssetGroup].
  this;

  /// The assets in this group.
  final List<DiscoveredAsset> assets = assets ?? [];

  /// The enum class name for this group.
  String enumClassName(String prefix) {
    if (subcategory != null) {
      return '$prefix${_capitalize(subcategory!)}Icons';
    }
    return switch (category) {
      AssetCategory.icon => '${prefix}Icons',
      AssetCategory.illustration => '${prefix}Illustrations',
      AssetCategory.animation => '${prefix}Animations',
      AssetCategory.logo => '${prefix}Logos',
    };
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
