import 'package:asset_core/src/pico_asset.dart';
import 'package:asset_core/src/pico_asset_category.dart';
import 'package:asset_core/src/pico_asset_type.dart';

/// Contract for icon assets.
abstract interface class PicoIconAsset() implements PicoAsset {
  static const double sizeSmall = 16.0;
  static const double sizeMedium = 24.0;
  static const double sizeLarge = 32.0;
  static const List<PicoAssetType> supportedTypes = [PicoAssetType.svg];
  static const PicoAssetCategory category = PicoAssetCategory.icon;
}
