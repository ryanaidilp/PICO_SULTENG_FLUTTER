import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/vaccine_detail/controllers/vaccine_detail_controller.dart';

class VaccineDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VaccineDetailController>(
      () => VaccineDetailController(),
    );
  }
}
