import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/images/network_image/pico_network_image.dart';
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
                child: PicoNetworkImage(
                  url: widget.getImage(
                    widget.data[index],
                  ),
                  width: 0.9.sw,
                  height: 0.2.sh,
                  fit: BoxFit.fill,
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
