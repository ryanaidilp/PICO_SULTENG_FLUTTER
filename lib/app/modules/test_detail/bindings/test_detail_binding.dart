import 'package:get/get.dart';

import '../controllers/test_detail_controller.dart';

class TestDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestDetailController>(
      () => TestDetailController(),
    );
  }
}
