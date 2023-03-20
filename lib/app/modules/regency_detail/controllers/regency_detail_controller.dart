import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/regency_statistic.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

class RegencyDetailController extends GetxController
    with SingleGetTickerProviderMixin {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  late ApiProvider provider;
  RxList<RegencyStatistic> regencyStatistic =
      List<RegencyStatistic>.empty(growable: true).obs;
  RxList<String> tabs = List<String>.empty(growable: true).obs;

  RxString errorMsg = ''.obs;
  RxBool statisticError = false.obs;
  RxBool statisticLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    provider = GetInstance().find<ApiProvider>();
    loadRegencyStatistic();
    scrollController.addListener(checkIfScrolled);
  }

  void onTabChange() {
    scrollOffset.value = 0;
  }

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  bool checkIfRegencyStatisticLoaded() {
    return !statisticLoading.value && !statisticError.value;
  }

  Future<void> loadRegencyStatistic() async {
    statisticError.value = false;
    statisticLoading.value = true;
    try {
      final value = await provider.loadRegencyStatistic();

      if (regencyStatistic.isNotEmpty) {
        regencyStatistic.clear();
        tabs.clear();
      }

      regencyStatistic.addAll(value);
      tabController =
          TabController(length: regencyStatistic.length, vsync: this)
            ..addListener(onTabChange);
      tabs.addAll(value.map((e) => e.name).toList());
    } catch (e) {
      errorMsg.value = e.toString();
      statisticError.value = true;
    } finally {
      statisticLoading.value = false;
    }
  }


  @override
  void onClose() {
    scrollController.dispose();
    tabController.dispose();
    super.onClose();
  }
}
