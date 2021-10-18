import 'package:get/get.dart';

import '../controllers/in_app_web_page_controller.dart';

class InAppWebPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InAppWebPageController>(
      () => InAppWebPageController(),
    );
  }
}
