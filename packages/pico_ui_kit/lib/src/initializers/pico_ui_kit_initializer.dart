import 'package:asset_core/asset_core.dart';
import 'package:flutter/widgets.dart';
import 'package:pico_ui_kit/src/initializers/pico_asset_preload_initializer.dart';
import 'package:pico_ui_kit/src/initializers/pico_font_initializer.dart';

/// Unified initializer for the UI Kit.
abstract final class PicoUiKitInitializer() {
  static Future<void> initialize(
    BuildContext context, {
    List<PicoAsset>? customAssets,
    List<PicoAsset> additionalAssets = const [],
    bool parallelAssetLoading = true,
  }) async {
    await Future.wait([
      initializeFonts(),
      initializeAssets(
        context,
        customAssets: customAssets,
        additionalAssets: additionalAssets,
        parallel: parallelAssetLoading,
      ),
    ]);
  }

  static Future<void> initializeFonts() => PicoFontInitializer.initialize();

  static Future<void> initializeAssets(
    BuildContext context, {
    List<PicoAsset>? customAssets,
    List<PicoAsset> additionalAssets = const [],
    bool parallel = true,
  }) => AssetPreloadInitializer.initialize(
    context,
    customAssets: customAssets,
    additionalAssets: additionalAssets,
    parallel: parallel,
  );
}
