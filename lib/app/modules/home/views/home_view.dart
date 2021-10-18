import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_case.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_confirmed.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/carousel_with_indicator.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/image_placeholder.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/infographic_mini_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/menu_button.dart';
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
              onLoading: controller.onLoading,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.infographic_label.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.checkIfInfographicLoaded()) {
                    Get.toNamed(Routes.infographics, arguments: {
                      'infographics': controller.infographics,
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
          buildInfographicSlider(),
        ],
      ),
    );
  }

  Widget buildInfographicSlider() {
    if (!controller.infographicLoaded.value) {
      return LimitedBox(
        maxHeight: 250.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerWidget(width: 160.0, height: 160.0),
                  SizedBox(height: 4.0),
                  ShimmerWidget(width: 60.0, height: 10.0),
                  SizedBox(height: 4.0),
                  ShimmerWidget(width: 40.0, height: 10.0),
                ],
              ),
            );
          },
          itemCount: 5,
        ),
      );
    }

    if (controller.infographicError.value) {
      return ErrorPlaceHolderWidget(
        label: LocaleKeys.error_infographic.tr,
        onRetry: () {
          controller.loadInfographics();
        },
      );
    }

    return LimitedBox(
      maxHeight: 210.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          final infographic = controller.infographics[index];
          return SizedBox(
            width: 160.0,
            child: InfographicMiniCard(
              infographic: infographic,
              onTap: () {
                Get.toNamed(Routes.detailInfographic, arguments: {
                  'infographic': infographic,
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildSultengTodayTab(BuildContext context) {
    return ListView(
      children: [
        buildCarouselSliders(),
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

  Widget buildMenuContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: Get.width * 0.1,
              child: const Divider(thickness: 4.0),
            ),
          ),
          Text(
            LocaleKeys.menu_information_center.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22.0,
            ),
          ),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 4,
            shrinkWrap: true,
            children: [
              MenuButton(
                label: LocaleKeys.menu_data_title.tr,
                iconColor: Colors.blueAccent,
                icon: EvaIcons.barChart2Outline,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_data_title.tr,
                    LocaleKeys.menu_data_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_vaccine_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.syringe,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_vaccine_title.tr,
                    LocaleKeys.menu_vaccine_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_bed_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.bed,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_bed_title.tr,
                    LocaleKeys.menu_bed_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_contact_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.book,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_contact_title.tr,
                    LocaleKeys.menu_contact_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_isolation_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.userShield,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_isolation_title.tr,
                    LocaleKeys.menu_isolation_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_screening_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.stethoscope,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_screening_title.tr,
                    LocaleKeys.menu_screening_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_donation_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.wallet,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_donation_title.tr,
                    LocaleKeys.menu_donation_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_teleconsultation_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.firstAid,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_teleconsultation_title.tr,
                    LocaleKeys.menu_teleconsultation_url.tr,
                  );
                },
              ),
              MenuButton(
                label: LocaleKeys.menu_faq_title.tr,
                iconColor: Colors.blueAccent,
                icon: LineIcons.questionCircle,
                onTap: () {
                  controller.openLink(
                    LocaleKeys.menu_faq_title.tr,
                    LocaleKeys.menu_faq_url.tr,
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  PreferredSizeWidget buildTabBar() {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () {
            showGetBottomSheet(buildMenuContent());
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AspectRatio(
              aspectRatio: 2.0,
              child: ShimmerWidget(width: double.infinity, height: 1000.0),
            ),
          ),
          SizedBox(height: 6.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ShimmerWidget(width: 150.0, height: 10.0),
          )
        ],
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

    return CarouselWithIndicator(
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
      options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 2.0,
          onPageChanged: controller.onPageChanged),
      controller: controller.carouselController,
      currentIndex: controller.activeCarousel.value,
    );
  }
}
