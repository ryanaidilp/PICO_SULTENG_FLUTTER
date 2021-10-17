import 'package:get/get.dart';

import '../controllers/vaccine_detail_controller.dart';

class VaccineDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VaccineDetailController>(
      () => VaccineDetailController(),
    );
  }
}
