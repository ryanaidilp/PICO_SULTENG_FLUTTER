import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/data_detail/controllers/data_detail_controller.dart';

class DataDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DataDetailController>(
      () => DataDetailController(),
    );
  }
}
