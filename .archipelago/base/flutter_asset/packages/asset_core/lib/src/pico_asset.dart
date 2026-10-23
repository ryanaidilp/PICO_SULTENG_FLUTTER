import 'package:asset_core/src/pico_asset_data.dart';

/// Base interface for all type-safe asset enums.
abstract interface class PicoAsset() {
  /// Returns the metadata for this asset.
  PicoAssetData get data;

  /// Default semantic label for screen readers.
  String get defaultSemanticLabel;
}
