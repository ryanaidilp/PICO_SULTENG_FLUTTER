import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/banner.dart' as model;
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_vaccine.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';
import 'package:pico_sulteng_flutter/app/modules/home/providers/home_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeController extends GetxController with SingleGetTickerProviderMixin {
  RxInt activeCarousel = 0.obs;
  late HomeProvider homeProvider;
  late TabController tabController;
  late Statistic province;
  late ProvinceVaccine provinceVaccine;
  RxList<ProvinceTest> provinceTests =
      List<ProvinceTest>.empty(growable: true).obs;
  RxList<String> images = List<String>.empty(growable: true).obs;
  final CarouselController carouselController = CarouselController();
  RxList<model.Banner> banners = List<model.Banner>.empty(growable: true).obs;
  RxBool bannerLoaded = false.obs;
  RxBool provinceLoaded = false.obs;
  RxBool provinceTestLoaded = false.obs;
  RxBool provinceVaccineLoaded = false.obs;
  RefreshController refreshController = RefreshController();

  @override
  Future<void> onInit() async {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    homeProvider = GetInstance().find<HomeProvider>();
    tabController.addListener(onTabChange);
    await onLoading();
  }

  Future<void> loadProvince() async {
    final value = await homeProvider.loadProvince();
    province = value;
    provinceLoaded.value = true;
  }

  void onTabChange() {
    activeCarousel.value = tabController.index;
    if (tabController.index == 1) {}
  }

  Future<void> loadProvinceVaccine() async {
    final value = await homeProvider.loadProvinceVaccine();
    provinceVaccine = value;
    provinceVaccineLoaded.value = true;
  }

  Future<void> loadProvinceTest() async {
    if (provinceTests.isNotEmpty) {
      provinceTests.clear();
    }

    final value = await homeProvider.loadProvinceTest();
    provinceTests.addAll(value);
    provinceTestLoaded.value = true;
  }

  Future<void> loadBanners() async {
    if (banners.isNotEmpty) {
      banners.clear();
      images.clear();
      activeCarousel.value = 0;
    }

    final value = await homeProvider.loadBanners();
    banners.addAll(value);
    images.addAll(value.map((banner) => banner.image).toList());
    bannerLoaded.value = true;
  }

  Future<void> onRefresh() async {
    bannerLoaded.value = false;
    provinceLoaded.value = false;
    provinceTestLoaded.value = false;
    provinceVaccineLoaded.value = false;
    await loadBanners();
    await loadProvince();
    await loadProvinceTest();
    await loadProvinceVaccine();
    refreshController.refreshCompleted();
  }

  Future<void> onLoading() async {
    bannerLoaded.value = false;
    provinceLoaded.value = false;
    provinceTestLoaded.value = false;
    provinceVaccineLoaded.value = false;
    await loadBanners();
    await loadProvince();
    await loadProvinceTest();
    await loadProvinceVaccine();
    refreshController.loadComplete();
  }

  void onPageChanged(int index, CarouselPageChangedReason reason) {
    activeCarousel.value = index;
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
