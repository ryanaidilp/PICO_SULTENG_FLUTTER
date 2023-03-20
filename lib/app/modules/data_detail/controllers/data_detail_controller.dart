import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';

class DataDetailController extends GetxController {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();

  late Statistic province;
  late List<ProvinceTest> tests;
  late int totalTests;

  @override
  void onInit() {
    super.onInit();
    province = Get.arguments['province_data'] as Statistic;
    tests = Get.arguments['tests'] as List<ProvinceTest>;
    totalTests = Get.arguments['total_test'] as int;
    scrollController.addListener(checkIfScrolled);
  }

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
