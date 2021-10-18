import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_case.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_confirmed.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/image_placeholder.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/shimmer_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/total_test_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_card.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildTabBar(),
      body: Obx(
        () => TabBarView(
          controller: controller.tabController,
          children: [
            SmartRefresher(
              controller: controller.refreshController,
              header: WaterDropHeader(
                waterDropColor: Colors.blue.shade200,
                completeDuration: const Duration(seconds: 2),
                complete: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      color: Colors.green.shade500,
                    ),
                    const SizedBox(width: 10.0),
                    Text(LocaleKeys.success_refresh.tr)
                  ],
                ),
              ),
              onRefresh: controller.onRefresh,
              primary: true,
              enableTwoLevel: true,
              child: buildSultengTodayTab(context),
            ),
            buildCovidInfoTab(),
          ],
        ),
      ),
    );
  }

  Widget buildCovidInfoTab() {
    return Center(
      child: Lottie.asset(
        'assets/lottie/coming_soon.json',
        width: Get.width * 0.6,
      ),
    );
  }

  Widget buildSultengTodayTab(BuildContext context) {
    return ListView(
      children: [
        buildCarouselSliders(),
        buildCarouselIndicator(context),
        const LineContainer(),
        buildTodayCaseAndTestSection(),
        const LineContainer(),
        buildVaccineSection(),
      ],
    );
  }

  Widget buildVaccineSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.vaccine_label.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.checkIfProvinceVaccinesLoaded()) {
                    Get.toNamed(Routes.vaccineDetail, arguments: {
                      'province_vaccine': controller.provinceVaccine,
                    });
                  }
                },
                child: Text(
                  LocaleKeys.buttons_more.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ],
          ),
          buildFirstVaccineSection(),
        ],
      ),
    );
  }

  Widget buildFirstVaccineSection() {
    if (!controller.provinceVaccineLoaded.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(width: Get.width * 0.25, height: 10.0),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: double.infinity,
            height: 140.0,
            highlightColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: double.infinity,
            height: 140.0,
            highlightColor: Colors.grey.shade200,
          ),
        ],
      );
    }

    if (controller.provinceVaccineError.value) {
      return ErrorPlaceHolderWidget(
        label: LocaleKeys.error_vaccine.tr,
        onRetry: () {
          controller.loadProvinceVaccine();
        },
      );
    }

    final provinceVaccine = controller.provinceVaccine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(buildUpdatedAtText(provinceVaccine.updatedAt)),
        const SizedBox(height: 16.0),
        VaccineCard(
          title: LocaleKeys.vaccine_type_first.tr,
          color: Colors.green.shade700,
          total: provinceVaccine.totalTarget,
          newCase: provinceVaccine.totalFirstNew,
          progress: provinceVaccine.totalFirstCumulative,
        ),
        const SizedBox(height: 16.0),
        VaccineCard(
          title: LocaleKeys.vaccine_type_second.tr,
          color: Colors.green.shade700,
          total: provinceVaccine.totalTarget,
          newCase: provinceVaccine.totalSecondNew,
          progress: provinceVaccine.totalSecondCumulative,
        ),
      ],
    );
  }

  Widget buildTodayCaseAndTestSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.data_case_label.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.checkIfProvinceDataLoaded() &&
                      controller.checkIfProvinceTestLoaded() &&
                      controller.checkIfProvinceVaccinesLoaded()) {
                    final int totalTest = controller.provinceTests
                        .fold(0, (sum, element) => sum + element.total);

                    Get.toNamed(Routes.dataDetail, arguments: {
                      'province_data': controller.province,
                      'total_test': totalTest,
                      'tests': controller.provinceTests
                    });
                  }
                },
                child: Text(
                  LocaleKeys.buttons_more.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ],
          ),
          buildProvinceSection(),
          const SizedBox(height: 8.0),
          buildTotalTestSection(),
        ],
      ),
    );
  }

  Widget buildTotalTestSection() {
    if (!controller.provinceTestLoaded.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: ShimmerWidget(
          width: double.infinity,
          height: 80.0,
          highlightColor: Colors.grey.shade50,
        ),
      );
    }

    if (controller.provinceTestError.value) {
      return ErrorPlaceHolderWidget(
        label: LocaleKeys.error_test.tr,
        onRetry: () {
          controller.loadProvinceTest();
        },
      );
    }

    return TotalTestCard(
      total: controller.provinceTests
          .fold(0, (sum, element) => sum + element.total),
      onPressed: () {
        if (controller.checkIfProvinceTestLoaded()) {
          Get.toNamed(Routes.testDetail, arguments: {
            'tests': controller.provinceTests,
          });
        }
      },
    );
  }

  Widget buildProvinceSection() {
    if (!controller.provinceLoaded.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(width: Get.width * 0.25, height: 10.0),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: double.infinity,
            height: 80.0,
            highlightColor: Colors.red.shade50,
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 4,
            children: [
              ShimmerWidget(
                width: Get.width * 0.3,
                height: 100.0,
                highlightColor: Colors.blue.shade50,
              ),
              ShimmerWidget(
                width: Get.width * 0.3,
                height: 100.0,
                highlightColor: Colors.green.shade50,
              ),
              ShimmerWidget(
                width: Get.width * 0.3,
                height: 100.0,
                highlightColor: Colors.orange.shade50,
              ),
            ],
          )
        ],
      );
    }

    if (controller.provinceError.value) {
      return ErrorPlaceHolderWidget(
        label: LocaleKeys.error_statistic.tr,
        onRetry: () {
          controller.loadProvince();
        },
      );
    }

    final province = controller.province;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(buildUpdatedAtText(province.updatedAt)),
        CardConfirmed(
          total: province.totalPositive,
          newCase: province.newPositive,
          startColor: Colors.redAccent,
          endColor: Colors.red.shade200,
          shadowColor: Colors.red.shade100,
        ),
        // const SizedBox(height: 4.0),

        Wrap(
          children: [
            SizedBox(
              width: Get.width * 0.3,
              child: CardCase(
                newCase: province.newTreatment,
                total: province.totalTreatment,
                icon: Iconsax.hospital,
                bgColorIcon: Colors.blue.shade50,
                colorIcon: Colors.blueAccent,
                label: LocaleKeys.card_case_label_under_treatment.tr,
              ),
            ),
            SizedBox(
              width: Get.width * 0.3,
              child: CardCase(
                newCase: province.newRecovered,
                total: province.totalRecovered,
                icon: Icons.check_rounded,
                bgColorIcon: Colors.green.shade50,
                colorIcon: Colors.green,
                label: LocaleKeys.card_case_label_recovered.tr,
              ),
            ),
            SizedBox(
              width: Get.width * 0.3,
              child: CardCase(
                newCase: province.newDeceased,
                total: province.totalDeceased,
                icon: Icons.close_rounded,
                bgColorIcon: Colors.orange.shade50,
                colorIcon: Colors.orange,
                label: LocaleKeys.card_case_label_deceased.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget buildTabBar() {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () {
            Get.snackbar(
              LocaleKeys.coming_soon.tr,
              LocaleKeys.menu_unavailable.tr,
              backgroundColor: Colors.red,
              icon: const Icon(
                Iconsax.danger,
                color: Colors.white,
              ),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              overlayBlur: 6.0,
              shouldIconPulse: true,
            );
          },
          icon: const Icon(
            Iconsax.menu_14,
            color: Colors.black,
          ),
        ),
      ],
      leading: Image.asset(
        'assets/images/logo.png',
        width: 10.0,
        height: 10.0,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.app_name.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            LocaleKeys.app_desc.tr,
            style: const TextStyle(
              fontSize: 10.0,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
      bottom: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: Colors.blueAccent,
        controller: controller.tabController,
        labelStyle: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w700,
        ),
        indicator: BubbleTabIndicator(
          indicatorHeight: Get.height * 0.04,
          indicatorColor: Colors.blueAccent,
          tabBarIndicatorSize: TabBarIndicatorSize.tab,
          insets: const EdgeInsets.symmetric(horizontal: 14.0),
          padding: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
        ),
        tabs: [
          Tab(
            text: LocaleKeys.tab_label_sulteng_today.tr,
          ),
          Tab(
            text: LocaleKeys.tab_label_covid_info.tr,
          ),
        ],
      ),
    );
  }

  Widget buildCarouselSliders() {
    if (!controller.bannerLoaded.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: AspectRatio(
          aspectRatio: 2.0,
          child: ShimmerWidget(width: double.infinity, height: 1000.0),
        ),
      );
    }

    if (controller.bannerError.value) {
      return ErrorPlaceHolderWidget(
        label: LocaleKeys.error_banner.tr,
        onRetry: () {
          controller.loadBanners();
        },
      );
    }

    return CarouselSlider(
      items: controller.banners
          .map(
            (banner) => Container(
              margin: const EdgeInsets.all(5.0),
              child: InkWell(
                onTap: () {
                  final StringBuffer buffer = StringBuffer();
                  buffer.writeAll([banner.urlType, banner.url]);
                  launch(buffer.toString());
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  child: ExtendedImage.network(
                    banner.image,
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
                              child:
                                  SpinKitFadingCircle(color: Colors.blueAccent),
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
                    },
                  ),
                ),
              ),
            ),
          )
          .toList(),
      carouselController: controller.carouselController,
      options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 2.0,
          onPageChanged: controller.onPageChanged),
    );
  }

  Widget buildCarouselIndicator(BuildContext context) {
    if (!controller.bannerLoaded.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ShimmerWidget(width: 250.0, height: 20.0),
      );
    }

    if (controller.bannerError.value) {
      return const SizedBox();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: controller.images.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () => controller.carouselController.animateToPage(entry.key),
          child: Container(
            width: controller.activeCarousel.value == entry.key ? 26.0 : 10.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            decoration: BoxDecoration(
                borderRadius: controller.activeCarousel.value == entry.key
                    ? BorderRadius.circular(8.0)
                    : null,
                shape: controller.activeCarousel.value == entry.key
                    ? BoxShape.rectangle
                    : BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade100
                        : Colors.blueAccent)
                    .withOpacity(controller.activeCarousel.value == entry.key
                        ? 0.9
                        : 0.3)),
          ),
        );
      }).toList(),
    );
  }
}
