/// Defines the rendering type of an asset.
enum PicoAssetType() {
  lottie,
  raster,
  svg,
}

extension PicoAssetTypeExtension on PicoAssetType {
  List<String> get extensions => switch (this) {
    PicoAssetType.lottie => ['.json', '.lottie'],
    PicoAssetType.raster => ['.png', '.jpg', '.jpeg', '.webp'],
    PicoAssetType.svg => ['.svg'],
  };

  bool get supportsColorOverride => switch (this) {
    PicoAssetType.lottie => false,
    PicoAssetType.raster => true,
    PicoAssetType.svg => true,
  };

  bool get supportsAnimation => this == PicoAssetType.lottie;
  bool get isSvg => this == PicoAssetType.svg;
  bool get isLottie => this == PicoAssetType.lottie;
  bool get isRaster => this == PicoAssetType.raster;

  String get fileExtension => switch (this) {
    PicoAssetType.lottie => '.json',
    PicoAssetType.raster => '.png',
    PicoAssetType.svg => '.svg',
  };

  static PicoAssetType fromPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.json') || lowerPath.endsWith('.lottie')) {
      return PicoAssetType.lottie;
    }
    if (lowerPath.endsWith('.svg')) return PicoAssetType.svg;
    if (lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.webp')) {
      return PicoAssetType.raster;
    }
    throw ArgumentError('Unknown asset type for path: $path');
  }
}
