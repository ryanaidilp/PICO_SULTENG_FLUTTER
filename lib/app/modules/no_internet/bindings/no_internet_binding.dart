import 'package:get/get.dart';

import '../controllers/no_internet_controller.dart';

class NoInternetBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NoInternetController>(
      NoInternetController(),
    );
  }
}
