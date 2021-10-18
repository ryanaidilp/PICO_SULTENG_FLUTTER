import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class InfographicsController extends GetxController
    with SingleGetTickerProviderMixin {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(checkIfScrolled);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
