import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/test_detail/controllers/test_detail_controller.dart';

class TestDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestDetailController>(
      () => TestDetailController(),
    );
  }
}
