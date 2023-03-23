import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/detail_infographic/controllers/detail_infographic_controller.dart';

class DetailInfographicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailInfographicController>(
      () => DetailInfographicController(),
    );
  }
}
