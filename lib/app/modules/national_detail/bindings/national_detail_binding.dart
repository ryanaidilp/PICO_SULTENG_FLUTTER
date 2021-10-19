import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

import '../controllers/national_detail_controller.dart';

class NationalDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiProvider());
    Get.lazyPut<NationalDetailController>(
      () => NationalDetailController(),
    );
  }
}
