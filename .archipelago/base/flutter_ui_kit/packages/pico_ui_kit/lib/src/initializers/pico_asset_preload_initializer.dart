import 'package:asset_core/asset_core.dart';
import 'package:flutter/widgets.dart';
import 'package:pico_ui_kit/src/utilities/asset_precacher.dart';

/// Initializer for preloading critical assets during app startup.
abstract final class AssetPreloadInitializer() {
  static List<PicoAsset> get defaultCriticalAssets => [];

  static Future<void> initialize(
    BuildContext context, {
    List<PicoAsset>? customAssets,
    List<PicoAsset> additionalAssets = const [],
    bool parallel = true,
  }) async {
    final assets =
        customAssets ?? [...defaultCriticalAssets, ...additionalAssets];
    if (assets.isEmpty) return;
    await AssetPrecacher.precache(context, assets: assets, parallel: parallel);
  }
}
