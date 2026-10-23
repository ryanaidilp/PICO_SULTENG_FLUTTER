import 'dart:async';

import 'package:asset_core/asset_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/utilities/lottie_cache.dart';

/// A utility class for pre-caching assets.
class AssetPrecacher._() {
  static Future<void> precache(
    BuildContext context, {
    required List<PicoAsset> assets,
    bool parallel = true,
  }) async {
    if (parallel) {
      await Future.wait(assets.map((a) => _precacheAsset(context, a)));
    } else {
      for (final a in assets) {
        await _precacheAsset(context, a);
      }
    }
  }

  static Future<void> _precacheAsset(
    BuildContext context,
    PicoAsset asset,
  ) async {
    switch (asset.data.type) {
      case PicoAssetType.svg:
        await _precacheSvg(context, asset.data);
      case PicoAssetType.lottie:
        await lottieCache.load(
          asset.data.path,
          package: asset.data.packageName,
        );
      case PicoAssetType.raster:
        await precacheImage(
          AssetImage(asset.data.path, package: asset.data.packageName),
          context,
        );
    }
  }

  static Future<void> _precacheSvg(
    BuildContext context,
    PicoAssetData data,
  ) async {
    final loader = SvgAssetLoader(data.path, packageName: data.packageName);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  }
}
