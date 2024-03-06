import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/src/utils/utils.dart';

class PicoNetworkImage extends StatelessWidget {
  const PicoNetworkImage({
    required this.url,
    super.key,
    this.width,
    this.height,
    this.border,
    this.borderRadius,
    this.repeat = ImageRepeat.noRepeat,
    this.fit = BoxFit.cover,
  });

  final double? width;
  final double? height;
  final ImageRepeat repeat;
  final BoxFit fit;
  final Border? border;
  final BorderRadius? borderRadius;
  final String url;

  @override
  Widget build(BuildContext context) => ExtendedImage.network(
        url,
        border: border ??
            Border.all(
              color: context.picoColors.background.neutral.strong,
            ),
        height: height,
        width: width,
        fit: fit,
        loadStateChanged: (state) => switch (state.extendedImageLoadState) {
          LoadState.loading => ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(0.r),
              child: Container(
                width: width,
                height: height,
                color: context.picoColors.background.neutral.white,
              ).sekeletonize(),
            ),
          LoadState.failed => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: context.picoColors.background.neutral.subtle,
              ),
              child: Material(
                borderRadius: borderRadius,
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: () => state.reLoadImage(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: context.picoColors.icon.neutral.strong,
                        ),
                        8.verticalSpace,
                        Text(
                          context.translations.general.button.tryAgain,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: context.picoColors.text.neutral.strong,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          LoadState.completed => ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(0.r),
              child: state.completedWidget,
            ),
        },
        clearMemoryCacheWhenDispose: true,
        borderRadius: borderRadius,
      );
}
