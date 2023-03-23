import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

import 'package:pico_sulteng_flutter/app/modules/regency_detail/controllers/regency_detail_controller.dart';

class RegencyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiProvider>(() => ApiProvider());
    Get.lazyPut<RegencyDetailController>(
      () => RegencyDetailController(),
    );
  }
}
