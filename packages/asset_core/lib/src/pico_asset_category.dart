/// Defines the category/purpose of an asset.
enum PicoAssetCategory() {
  animation,
  icon,
  illustration,
  logo,
}

extension PicoAssetCategoryExtension on PicoAssetCategory {
  String get directoryName => switch (this) {
    PicoAssetCategory.animation => 'animations',
    PicoAssetCategory.icon => 'icons',
    PicoAssetCategory.illustration => 'illustrations',
    PicoAssetCategory.logo => 'logos',
  };

  bool get defaultColorOverride => switch (this) {
    PicoAssetCategory.animation => false,
    PicoAssetCategory.icon => true,
    PicoAssetCategory.illustration => false,
    PicoAssetCategory.logo => false,
  };
}
