import 'package:carousel_slider/carousel_options.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/carousel_with_indicator.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/image_placeholder.dart';
import 'package:pico_sulteng_flutter/app/modules/detail_infographic/controllers/detail_infographic_controller.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailInfographicView extends GetView<DetailInfographicController> {
  const DetailInfographicView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final infographic = controller.infographic.value!;

        return Scaffold(
          body: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                iconTheme: const IconThemeData(
                  color: Colors.white,
                ),
                expandedHeight: 400,
                flexibleSpace: CarouselWithIndicator(
                  items: infographic.images
                      .map(
                        (image) => ExtendedImage.network(
                          image as String,
                          clearMemoryCacheWhenDispose: true,
                          fit: BoxFit.fill,
                          width: double.infinity,
                          loadStateChanged: (ExtendedImageState state) {
                            switch (state.extendedImageLoadState) {
                              case LoadState.loading:
                                return const ImagePlaceholder(
                                  label: 'Loading',
                                  child: SizedBox(
                                    width: 50.0,
                                    child: SpinKitFadingCircle(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                );
                              case LoadState.failed:
                                return InkWell(
                                  onTap: () {
                                    state.reLoadImage();
                                  },
                                  child: const ImagePlaceholder(
                                    label: 'Error',
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              case LoadState.completed:
                                break;
                            }
                            return null;
                          },
                        ),
                      )
                      .toList(),
                  currentIndex: controller.activeCarousel.value,
                  controller: controller.carouselController,
                  options: CarouselOptions(
                    onPageChanged: controller.onPageChanged,
                    autoPlay: true,
                    height: 350,
                    viewportFraction: 1.0,
                    autoPlayInterval: const Duration(seconds: 5),
                  ),
                ),
              ),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateWithDayFormat(
                          infographic.publishedAt,
                          format: 'EEEE, dd MMMM yyyy HH:mm',
                          includeTimeZone: true,
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: Text(
                          infographic.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 26.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: 10.0,
                            shadowColor: Colors.blue.shade100,
                          ),
                          child: Text(
                            LocaleKeys.buttons_source.tr,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            launchUrl(Uri.parse(infographic.link));
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
