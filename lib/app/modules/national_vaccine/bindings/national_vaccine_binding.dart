import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

import '../controllers/national_vaccine_controller.dart';

class NationalVaccineBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiProvider>(() => ApiProvider());
    Get.lazyPut<NationalVaccineController>(
      () => NationalVaccineController(),
    );
  }
}
