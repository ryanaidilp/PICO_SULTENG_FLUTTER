import 'package:get/get.dart';

import '../controllers/data_detail_controller.dart';

class DataDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DataDetailController>(
      () => DataDetailController(),
    );
  }
}
