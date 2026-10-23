import 'package:asset_core/src/pico_asset.dart';
import 'package:asset_core/src/pico_asset_category.dart';
import 'package:asset_core/src/pico_asset_type.dart';

/// Contract for logo assets.
abstract interface class PicoLogoAsset() implements PicoAsset {
  static const double sizeSmall = 32.0;
  static const double sizeMedium = 48.0;
  static const double sizeLarge = 64.0;
  static const List<PicoAssetType> supportedTypes = [
    PicoAssetType.svg,
    PicoAssetType.raster,
  ];
  static const PicoAssetCategory category = PicoAssetCategory.logo;
}
