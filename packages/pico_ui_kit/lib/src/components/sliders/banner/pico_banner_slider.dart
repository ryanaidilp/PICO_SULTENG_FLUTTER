import 'package:carousel_slider/carousel_slider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PicoBannerSlider<T> extends StatefulWidget {
  const PicoBannerSlider({
    required this.data,
    required this.getImage,
    this.onItemTap,
    super.key,
  });

  final List<T> data;
  final String Function(T item) getImage;
  final void Function(T item)? onItemTap;

  @override
  State<PicoBannerSlider<T>> createState() => _PicoBannerSliderState<T>();
}

class _PicoBannerSliderState<T> extends State<PicoBannerSlider<T>> {
  late final ValueNotifier<int> _activePageNotifier;
  late final CarouselController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselController();
    _activePageNotifier = ValueNotifier(0);
  }

  @override
  void dispose() {
    _activePageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          CarouselSlider.builder(
            itemCount: widget.data.length,
            carouselController: _carouselController,
            itemBuilder: (context, index, realIndex) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  widget.onItemTap?.call(widget.data[index]);
                },
                child: ExtendedImage.network(
                  widget.getImage(
                    widget.data[index],
                  ),
                  border: Border.all(
                    color: context.picoColors.background.strong,
                  ),
                  height: 0.2.sh,
                  fit: BoxFit.fill,
                  loadStateChanged: (state) =>
                      switch (state.extendedImageLoadState) {
                    LoadState.loading => ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 0.9.sw,
                          height: 0.2.sh,
                          color: context.picoColors.background.white,
                        ).sekeletonize(),
                      ),
                    LoadState.failed => Container(
                        width: 0.9.sw,
                        height: 0.2.sh,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: context.picoColors.background.subtle,
                        ),
                        child: Material(
                          borderRadius: BorderRadius.circular(12.r),
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.r),
                            onTap: () => state.reLoadImage(),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_rounded,
                                    color: context.picoColors.background.strong,
                                  ),
                                  8.verticalSpace,
                                  Text(
                                    context.i10n.buttons.try_again,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: context
                                              .picoColors.text.neutral.strong,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    LoadState.completed => ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: state.completedWidget,
                      ),
                  },
                  clearMemoryCacheWhenDispose: true,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 2,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                _activePageNotifier.value = index;
              },
            ),
          ),
          16.verticalSpace,
          ValueListenableBuilder(
            valueListenable: _activePageNotifier,
            builder: (_, activePage, child) => AnimatedSmoothIndicator(
              activeIndex: activePage,
              onDotClicked: (index) => _carouselController.animateToPage(index),
              effect: ExpandingDotsEffect(
                activeDotColor: context.picoColors.icon.semantic.primary,
                dotColor: context.picoColors.background.strong,
                dotWidth: 8.w,
                dotHeight: 8.h,
                spacing: 4.w,
              ),
              count: widget.data.length,
            ),
          ),
        ],
      );
}
