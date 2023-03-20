import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/vaccine.dart';

class VaccineDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  late Vaccine provinceVaccine;

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    provinceVaccine = Get.arguments['province_vaccine'] as Vaccine;
    tabController = TabController(length: 2, vsync: this);
    scrollController.addListener(checkIfScrolled);
  }

  @override
  void onClose() {
    scrollController.dispose();
    tabController.dispose();
    super.onClose();
  }
}
