import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_case.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_confirmed.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/suspect_case_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/total_test_card.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

import '../controllers/data_detail_controller.dart';

class DataDetailView extends GetView<DataDetailController> {
  final Statistic province = Get.arguments['province_data'] as Statistic;
  final List<ProvinceTest> tests = Get.arguments['tests'] as List<ProvinceTest>;
  final int totalTests = Get.arguments['total_test'] as int;

  Widget buildBottomSheet(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: Get.width * 0.1,
              child: const Divider(thickness: 4.0),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            content,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () => Scaffold(
          appBar: AppBar(
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: controller.scrollOffset.value,
              child: Text(
                LocaleKeys.data_case_label.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            controller: controller.scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.data_case_label.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(buildUpdatedAtText(province.updatedAt)),
                  CardConfirmed(
                    total: province.totalPositive,
                    newCase: province.newPositive,
                    startColor: Colors.redAccent,
                    endColor: Colors.red.shade200,
                    shadowColor: Colors.red.shade100,
                  ),
                  // const SizedBox(height: 4.0),
                  Wrap(
                    children: [
                      SizedBox(
                        width: Get.width * 0.3,
                        child: CardCase(
                          newCase: province.newTreatment,
                          total: province.totalTreatment,
                          icon: Iconsax.hospital,
                          bgColorIcon: Colors.blue.shade50,
                          colorIcon: Colors.blueAccent,
                          label: LocaleKeys.card_case_label_under_treatment.tr,
                        ),
                      ),
                      SizedBox(
                        width: Get.width * 0.3,
                        child: CardCase(
                          newCase: province.newRecovered,
                          total: province.totalRecovered,
                          icon: Icons.check_rounded,
                          bgColorIcon: Colors.green.shade50,
                          colorIcon: Colors.green,
                          label: LocaleKeys.card_case_label_recovered.tr,
                        ),
                      ),
                      SizedBox(
                        width: Get.width * 0.3,
                        child: CardCase(
                          newCase: province.newDeceased,
                          total: province.totalDeceased,
                          icon: Icons.close_rounded,
                          bgColorIcon: Colors.orange.shade50,
                          colorIcon: Colors.orange,
                          label: LocaleKeys.card_case_label_deceased.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  SuspectCaseCard(
                    title: 'Total Orang Dalam Pemantauan',
                    total: province.totalObservation,
                    newCase: province.newObservation,
                    newFinishedCase: province.newFinishedObservation,
                    activeCase: province.totalActiveObservation,
                    finishedCase: province.totalFinishedObservation,
                    onTap: () {
                      showGetBottomSheet(
                        buildBottomSheet(
                          'ODP (Orang Dalam Pemantauan)',
                          'Orang dalam pemantauan (ODP) adalah seseorang yang mengalami demam (≥38°C) atau riwayat demam; atau gejala gangguan sistem pernapasan, seperti pilek/sakit tenggorokan/batuk DAN tidak ada penyebab lain berdasarkan gambaran klinis yang meyakinkan DAN pada 14 hari terakhir sebelum timbul gejala, memenuhi salah satu kriteria: “memiliki riwayat perjalanan atau tinggal di luar negeri yang melaporkan transmisi lokal” atau “memiliki riwayat perjalanan atau tinggal di area transmisi lokal di Indonesia”.',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  SuspectCaseCard(
                    title: 'Total Pasien Dalam Pengawasan',
                    total: province.totalSupervision,
                    newCase: province.newSupervision,
                    newFinishedCase: province.newFinishedSupervision,
                    activeCase: province.totalActiveSupervision,
                    finishedCase: province.totalFinishedSupervision,
                    onTap: () {
                      showGetBottomSheet(
                        buildBottomSheet(
                          'PDP (Pasien Dalam Pengawasan)',
                          'Pasien Dalam Pengawasan adalah seseorang dengan Infeksi Saluran Pernapasan Akut (ISPA) yaitu demam (≥38°C) atau riwayat demam; disertai salah satu gejala/tanda penyakit pernapasan seperti: batuk/sesak nafas/sakit tenggorokan/pilek/pneumonia ringan hingga berat DAN tidak ada penyebab lain berdasarkan gambaran klinis yang meyakinkan DAN pada 14 hari terakhir sebelum timbul gejala, memenuhi salah satu kriteria: "memiliki riwayat perjalanan atau tinggal di luar negeri yang melaporkan transmisi lokal" atau "memiliki riwayat perjalanan atau tinggal di area transmisi lokal di Indonesia.',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  TotalTestCard(
                    total: totalTests,
                    onPressed: () {
                      Get.toNamed(Routes.testDetail,
                          arguments: {'tests': tests});
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
