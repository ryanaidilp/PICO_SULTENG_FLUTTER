import 'package:asset_core/src/pico_asset.dart';
import 'package:asset_core/src/pico_asset_category.dart';
import 'package:asset_core/src/pico_asset_type.dart';

/// Contract for illustration assets.
abstract interface class PicoIllustrationAsset() implements PicoAsset {
  static const double sizeSmall = 120.0;
  static const double sizeMedium = 200.0;
  static const double sizeLarge = 300.0;
  static const List<PicoAssetType> supportedTypes = [
    PicoAssetType.svg,
    PicoAssetType.raster,
  ];
  static const PicoAssetCategory category = PicoAssetCategory.illustration;
}
