import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VaccineDetailController extends GetxController
    with SingleGetTickerProviderMixin {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
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
