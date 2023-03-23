import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/vaccine.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

class NationalVaccineController extends GetxController
    with SingleGetTickerProviderMixin {
  late Vaccine vaccine;
  late ApiProvider provider;
  late TabController tabController;
  late ScrollController scrollController;

  RxString errorMsg = ''.obs;
  RxDouble scrollOffset = 0.0.obs;
  RxBool vaccineError = false.obs;
  RxBool vaccineLoading = true.obs;

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    provider = GetInstance().find<ApiProvider>();
    tabController = TabController(length: 2, vsync: this);
    scrollController = ScrollController()..addListener(checkIfScrolled);
    loadNationalVaccine();
  }

  Future<void> loadNationalVaccine() async {
    errorMsg.value = '';
    vaccineError.value = false;
    vaccineLoading.value = true;
    try {
      final data = await provider.loadNationalVaccine();
      vaccine = data;
    } catch (e) {
      vaccineError.value = true;
      errorMsg.value = e.toString();
    } finally {
      vaccineLoading.value = false;
    }
  }


  @override
  void onClose() {
    scrollController.dispose();
    tabController.dispose();
    super.onClose();
  }
}
