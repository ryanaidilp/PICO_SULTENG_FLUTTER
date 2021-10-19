import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

import '../controllers/articles_controller.dart';

class ArticlesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiProvider>(() => ApiProvider());
    Get.lazyPut<ArticlesController>(
      () => ArticlesController(),
    );
  }
}
