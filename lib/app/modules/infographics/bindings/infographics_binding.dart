import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

import '../controllers/infographics_controller.dart';

class InfographicsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiProvider>(
      () => ApiProvider(),
    );
    Get.lazyPut<InfographicsController>(
      () => InfographicsController(),
    );
  }
}
