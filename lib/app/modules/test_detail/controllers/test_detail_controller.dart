import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestDetailController extends GetxController
    with SingleGetTickerProviderMixin {
  late TabController tabController;
  RxInt currentTab = 0.obs;
  List<String> testDescriptions = <String>[
    'Polymerase Chain Reaction atau PCR merupakan pemeriksaan diagnostik yang dianggap paling akurat untuk memastikan apakah seseorang menderita COVID-19 atau tidak. Jumlah tes PCR yang ditampilkan diolah dari data yang dipublikasikan Dinas Kesehatan Sulawesi Tengah.',
    'Rapid Diagnostic Test (RDT) atau test diagnostik cepat merupakan test yang digunakan sebagai skrining medis awal untuk mendeteksi COVID-19. Pada hasil RDT yang Reaktif akan dilakukan pemeriksaan konfirmasi lebih lanjut dengan metode SWAB/Polymerase Chain Reaction (PCR).'
  ];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(onTabChanges);
  }


  void onTabChanges() {
    currentTab.value = tabController.index;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
