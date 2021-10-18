import 'package:get/get.dart';

import '../controllers/detail_infographic_controller.dart';

class DetailInfographicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailInfographicController>(
      () => DetailInfographicController(),
    );
  }
}
