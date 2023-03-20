import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/no_internet/controllers/no_internet_controller.dart';

class NoInternetBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NoInternetController>(
      NoInternetController(),
    );
  }
}
