import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pico_sulteng_flutter/app/data/models/banner.dart' as model;
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_vaccine.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeController extends GetxController with SingleGetTickerProviderMixin {
  RxInt activeCarousel = 0.obs;
  late ApiProvider provider;
  late TabController tabController;
  late Statistic province;
  late ProvinceVaccine provinceVaccine;
  RxList<ProvinceTest> provinceTests =
      List<ProvinceTest>.empty(growable: true).obs;
  RxList<Infographic> infographics =
      List<Infographic>.empty(growable: true).obs;
  RxList<String> images = List<String>.empty(growable: true).obs;
  final CarouselController carouselController = CarouselController();
  RxList<model.Banner> banners = List<model.Banner>.empty(growable: true).obs;
  RxBool bannerLoading = true.obs;
  RxBool provinceLoading = true.obs;
  RxBool provinceTestLoading = true.obs;
  RxBool provinceVaccineLoading = true.obs;
  RxBool infographicLoading = true.obs;
  RxBool bannerError = false.obs;
  RxBool provinceError = false.obs;
  RxBool provinceTestError = false.obs;
  RxBool provinceVaccineError = false.obs;
  RxBool infographicError = false.obs;
  late RefreshController refreshController = RefreshController();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(
      length: 2,
      vsync: this,
    )..addListener(onTabChange);
    provider = GetInstance().find<ApiProvider>();
    onLoading();
    OneSignal.shared.setNotificationWillShowInForegroundHandler(
        (OSNotificationReceivedEvent event) {
      // Will be called whenever a notification is received in foreground
      // Display Notification, pass null param for not displaying the notification
      loadProvince();
      event.complete(event.notification);
    });
  }

  Future<void> loadProvince() async {
    provinceError.value = false;
    provinceLoading.value = true;
    try {
      final value = await provider.loadProvince();
      province = value;
    } catch (e) {
      provinceError.value = true;
    } finally {
      provinceLoading.value = false;
    }
  }

  bool checkIfProvinceVaccinesLoaded() {
    return !provinceVaccineLoading.value && !provinceVaccineError.value;
  }

  bool checkIfBannerLoaded() {
    return !bannerLoading.value && !bannerError.value;
  }

  bool checkIfProvinceDataLoaded() {
    return !provinceLoading.value && !provinceError.value;
  }

  bool checkIfProvinceTestLoaded() {
    return !provinceTestLoading.value && !provinceTestError.value;
  }

  bool checkIfProvinceVaccineLoaded() {
    return !provinceVaccineLoading.value && !provinceVaccineError.value;
  }

  bool checkIfInfographicLoaded() {
    return !infographicLoading.value && !infographicError.value;
  }

  void onTabChange() {
    activeCarousel.value = tabController.index;
    if (tabController.index == 1 && infographics.isEmpty) {
      infographicLoading.value = false;
      loadInfographics();
    }
  }

  Future<void> loadProvinceVaccine() async {
    provinceVaccineError.value = false;
    provinceVaccineLoading.value = true;
    try {
      final value = await provider.loadProvinceVaccine();
      provinceVaccine = value;
    } catch (e) {
      provinceVaccineError.value = true;
    } finally {
      provinceVaccineLoading.value = false;
    }
  }

  Future<void> loadInfographics() async {
    infographicError.value = false;
    infographicLoading.value = true;
    try {
      if (infographics.isNotEmpty) {
        infographics.clear();
      }
      final value = await provider.loadInfographics(1);
      infographics.addAll(value);
    } catch (e) {
      infographicError.value = true;
    } finally {
      infographicLoading.value = false;
    }
  }

  Future<void> loadProvinceTest() async {
    provinceTestError.value = false;
    provinceTestLoading.value = true;
    try {
      if (provinceTests.isNotEmpty) {
        provinceTests.clear();
      }

      final value = await provider.loadProvinceTest();
      provinceTests.addAll(value);
    } catch (e) {
      provinceTestError.value = true;
    } finally {
      provinceTestLoading.value = false;
    }
  }

  Future<void> loadBanners() async {
    bannerError.value = false;
    bannerLoading.value = true;
    try {
      if (banners.isNotEmpty) {
        banners.clear();
        images.clear();
        activeCarousel.value = 0;
      }

      final value = await provider.loadBanners();
      banners.addAll(value);
      images.addAll(value.map((banner) => banner.image).toList());
    } catch (e) {
      bannerError.value = true;
    } finally {
      bannerLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await Future.wait([
      loadBanners(),
      loadProvince(),
      loadInfographics(),
      loadProvinceTest(),
      loadProvinceVaccine()
    ]);
    refreshController.refreshCompleted();
  }

  Future<void> onLoading() async {
    await Future.wait([
      loadBanners(),
      loadProvince(),
      loadProvinceTest(),
      loadProvinceVaccine()
    ]);
    refreshController.loadComplete();
  }

  void onPageChanged(int index, CarouselPageChangedReason reason) {
    activeCarousel.value = index;
  }

  void openLink(String title, String url) {
    if (Get.isBottomSheetOpen!) Get.back();
    Get.toNamed(
      Routes.inAppWebPage,
      arguments: {
        'title': title,
        'link': url,
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    tabController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
