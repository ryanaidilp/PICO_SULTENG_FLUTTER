import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoBannerSliderSkeleton extends StatelessWidget {
  const PicoBannerSliderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CarouselSlider.builder(
            itemCount: 3,
            itemBuilder: (_, __, ___) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: 0.9.sw,
                    height: 0.25.sh,
                    color: context.picoColors.background.neutral.white,
                  ).sekeletonize(),
                ),
              ),
            ),
            options: CarouselOptions(
              aspectRatio: 2,
              viewportFraction: 0.9,
            ),
          ),
          16.verticalSpace,
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: 0.15.sw,
                height: 8.h,
                color: context.picoColors.background.neutral.inverse,
              ).sekeletonize(),
            ),
          ),
        ],
      );
}
