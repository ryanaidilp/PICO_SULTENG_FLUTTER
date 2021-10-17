import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class DataDetailController extends GetxController {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(checkIfScrolled);
  }

  @override
  void onReady() {
    super.onReady();
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
