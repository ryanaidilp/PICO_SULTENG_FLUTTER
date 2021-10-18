import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/banner.dart' as model;
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_vaccine.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';
import 'package:pico_sulteng_flutter/app/modules/home/providers/home_provider.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeController extends GetxController with SingleGetTickerProviderMixin {
  RxInt activeCarousel = 0.obs;
  late HomeProvider homeProvider;
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
  RxBool bannerLoaded = false.obs;
  RxBool provinceLoaded = false.obs;
  RxBool provinceTestLoaded = false.obs;
  RxBool provinceVaccineLoaded = false.obs;
  RxBool infographicLoaded = false.obs;
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
    homeProvider = GetInstance().find<HomeProvider>();
    onLoading();
  }

  Future<void> loadProvince() async {
    provinceError.value = false;
    try {
      final value = await homeProvider.loadProvince();
      province = value;
      provinceLoaded.value = true;
    } catch (e) {
      provinceLoaded.value = false;
      provinceError.value = true;
    }
  }

  bool checkIfProvinceVaccinesLoaded() {
    return provinceVaccineLoaded.value && !provinceVaccineError.value;
  }

  bool checkIfBannerLoaded() {
    return bannerLoaded.value && !bannerError.value;
  }

  bool checkIfProvinceDataLoaded() {
    return provinceLoaded.value && !provinceError.value;
  }

  bool checkIfProvinceTestLoaded() {
    return provinceTestLoaded.value && !provinceTestError.value;
  }

  bool checkIfProvinceVaccineLoaded() {
    return provinceVaccineLoaded.value && !provinceVaccineError.value;
  }

  bool checkIfInfographicLoaded() {
    return infographicLoaded.value && !infographicError.value;
  }

  void onTabChange() {
    activeCarousel.value = tabController.index;
    if (tabController.index == 1 && infographics.isEmpty) {
      infographicLoaded.value = false;
      loadInfographics();
    }
  }

  Future<void> loadProvinceVaccine() async {
    provinceVaccineError.value = false;
    try {
      final value = await homeProvider.loadProvinceVaccine();
      provinceVaccine = value;
      provinceVaccineLoaded.value = true;
    } catch (e) {
      provinceVaccineLoaded.value = false;
      provinceVaccineError.value = true;
    }
  }

  Future<void> loadInfographics() async {
    infographicError.value = false;
    try {
      if (infographics.isNotEmpty) {
        infographics.clear();
      }
      final value = await homeProvider.loadInfographics();
      infographics.addAll(value);
      infographicLoaded.value = true;
    } catch (e) {
      infographicLoaded.value = false;
      infographicError.value = true;
    }
  }

  Future<void> loadProvinceTest() async {
    provinceTestError.value = false;
    try {
      if (provinceTests.isNotEmpty) {
        provinceTests.clear();
      }

      final value = await homeProvider.loadProvinceTest();
      provinceTests.addAll(value);
      provinceTestLoaded.value = true;
    } catch (e) {
      provinceTestLoaded.value = false;
      provinceTestError.value = true;
    }
  }

  Future<void> loadBanners() async {
    bannerError.value = false;
    try {
      if (banners.isNotEmpty) {
        banners.clear();
        images.clear();
        activeCarousel.value = 0;
      }

      final value = await homeProvider.loadBanners();
      banners.addAll(value);
      images.addAll(value.map((banner) => banner.image).toList());
      bannerLoaded.value = true;
    } catch (e) {
      bannerLoaded.value = false;
      bannerError.value = true;
    }
  }

  Future<void> onRefresh() async {
    bannerLoaded.value = false;
    provinceLoaded.value = false;
    infographicLoaded.value = false;
    provinceTestLoaded.value = false;
    provinceVaccineLoaded.value = false;
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
    bannerLoaded.value = false;
    provinceLoaded.value = false;
    provinceTestLoaded.value = false;
    provinceVaccineLoaded.value = false;
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
