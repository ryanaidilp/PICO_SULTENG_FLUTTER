import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/modules/home/providers/home_provider.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeProvider>(HomeProvider());
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}
