import 'package:asset_core/src/pico_asset.dart';
import 'package:asset_core/src/pico_asset_category.dart';
import 'package:asset_core/src/pico_asset_type.dart';

/// Contract for animation assets.
abstract interface class PicoAnimationAsset() implements PicoAsset {
  static const double sizeSmall = 80.0;
  static const double sizeMedium = 120.0;
  static const double sizeLarge = 200.0;
  static const List<PicoAssetType> supportedTypes = [PicoAssetType.lottie];
  static const PicoAssetCategory category = PicoAssetCategory.animation;
  bool get shouldRepeat => false;
  bool get shouldAutoPlay => true;
}
