import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_asset_type.dart';
import 'package:pico_ui_kit/src/components/asset/models/pico_asset_data.dart';

class PicoAsset extends StatelessWidget {
  const PicoAsset._({
    required PicoAssetType type,
    required this.data,
    this.repeat = false,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.imageRepeat,
    this.shape,
    this.width,
    this.height,
    this.color,
    this.border,
  }) : _type = type;

  factory PicoAsset.icon({
    required PicoIcons icon,
    double? size,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) =>
      PicoAsset._(
        type: PicoAssetType.icon,
        data: icon.data,
        width: size,
        height: size,
        fit: fit,
        color: color,
      );

  factory PicoAsset.animation({
    required PicoAnimations animation,
    double? width,
    double? height,
    bool repeat = true,
    BoxFit fit = BoxFit.contain,
  }) =>
      PicoAsset._(
        type: PicoAssetType.animation,
        data: animation.data,
        repeat: repeat,
        width: width,
        height: height,
        fit: fit,
      );

  factory PicoAsset.images({
    required PicoImages image,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    BoxShape? shape,
    BoxFit fit = BoxFit.contain,
    Border? border,
    ImageRepeat repeat = ImageRepeat.noRepeat,
  }) =>
      PicoAsset._(
        type: PicoAssetType.images,
        width: width,
        height: height,
        imageRepeat: repeat,
        border: border,
        borderRadius: borderRadius,
        shape: shape,
        fit: fit,
        data: image.data,
      );

  final PicoAssetType _type;
  final PicoAssetData data;
  final bool repeat;
  final ImageRepeat? imageRepeat;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Color? color;
  final BoxShape? shape;
  final Border? border;

  @override
  Widget build(BuildContext context) => switch (_type) {
        PicoAssetType.icon => SvgPicture.asset(
            data.path,
            fit: fit,
            height: (height ?? 0) * 1.sp,
            width: (width ?? 0) * 1.sp,
            colorFilter: color != null
                ? ColorFilter.mode(
                    color!,
                    BlendMode.srcIn,
                  )
                : null,
            package: 'pico_ui_kit',
          ),
        PicoAssetType.images => ExtendedImage.asset(
            data.path,
            width: (width ?? 0) * 1.w,
            height: (height ?? 0) * 1.h,
            borderRadius: borderRadius,
            repeat: imageRepeat!,
            shape: shape,
            package: 'pico_ui_kit',
          ),
        PicoAssetType.animation => Lottie.asset(
            data.path,
            width: (width ?? 0) * 1.w,
            height: (height ?? 0) * 1.h,
            repeat: repeat,
            fit: fit,
            package: 'pico_ui_kit',
          ),
      };
}
