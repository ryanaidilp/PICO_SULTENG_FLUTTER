import 'package:get/get.dart';

import '../controllers/infographics_controller.dart';

class InfographicsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfographicsController>(
      () => InfographicsController(),
    );
  }
}
