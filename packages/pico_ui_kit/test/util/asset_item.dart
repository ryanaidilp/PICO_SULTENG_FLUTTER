import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// A widget that displays an asset with its name label below.
class const AssetItem({
  required final PicoAsset asset,
  super.key,
  final double size = 24,
  final Color? color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isIcon = asset is PicoIconAsset;
    final isAnimation = asset is PicoAnimationAsset;
    final isLogo = asset is PicoLogoAsset;

    return SizedBox(
      width: size + 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: isIcon
                ? PicoAssetWidget.icon(
                    asset as PicoIconAsset,
                    size: size,
                    color: color,
                  )
                : isAnimation
                ? PicoAssetWidget.animation(
                    asset as PicoAnimationAsset,
                    size: size,
                    animate: false,
                  )
                : isLogo
                ? PicoAssetWidget.logo(
                    asset as PicoLogoAsset,
                    width: size,
                    height: size,
                  )
                : PicoAssetWidget(asset, width: size, height: size),
          ),
          const SizedBox(height: 4),
          Text(
            _label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String get _label => asset.toString().split('.').last;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PicoAsset>('asset', asset));
    properties.add(DoubleProperty('size', size));
    properties.add(ColorProperty('color', color));
  }
}
