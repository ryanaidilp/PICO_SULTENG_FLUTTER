import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/controllers/in_app_web_page_controller.dart';

class InAppWebPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InAppWebPageController>(
      () => InAppWebPageController(),
    );
  }
}
