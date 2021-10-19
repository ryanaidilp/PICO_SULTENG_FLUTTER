import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/national_statistic.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

class NationalDetailController extends GetxController {
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();

  late ApiProvider provider;
  late NationalStatistic nationalStatistic;

  RxString errorMsg = ''.obs;
  RxBool statisticError = false.obs;
  RxBool statisticLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    provider = GetInstance().find<ApiProvider>();
    scrollController.addListener(checkIfScrolled);
    loadNationalStatistic();
  }

  Future<void> loadNationalStatistic() async {
    statisticError.value = false;
    statisticLoading.value = true;
    try {
      final data = await provider.loadNationalStatistic();
      nationalStatistic = data;
    } catch (e) {
      statisticError.value = true;
      errorMsg.value = e.toString();
    } finally {
      statisticLoading.value = false;
    }
  }

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
