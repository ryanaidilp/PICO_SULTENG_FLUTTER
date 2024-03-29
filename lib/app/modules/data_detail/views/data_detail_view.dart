import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_case.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_confirmed.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/suspect_case_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/total_test_card.dart';
import 'package:pico_sulteng_flutter/app/modules/data_detail/controllers/data_detail_controller.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class DataDetailView extends GetView<DataDetailController> {
  const DataDetailView({super.key});

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
        () {
          final tests = controller.tests;
          final totalTests = controller.totalTests;
          final province = controller.province;
          return Scaffold(
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
                            label:
                                LocaleKeys.card_case_label_under_treatment.tr,
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
                      title: LocaleKeys.odp_label.tr,
                      total: province.totalObservation,
                      newCase: province.newObservation,
                      newFinishedCase: province.newFinishedObservation,
                      activeCase: province.totalActiveObservation,
                      finishedCase: province.totalFinishedObservation,
                      onTap: () {
                        showGetBottomSheet(
                          buildBottomSheet(
                            LocaleKeys.odp_title.tr,
                            LocaleKeys.odp_description.tr,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8.0),
                    SuspectCaseCard(
                      title: LocaleKeys.pdp_label.tr,
                      total: province.totalSupervision,
                      newCase: province.newSupervision,
                      newFinishedCase: province.newFinishedSupervision,
                      activeCase: province.totalActiveSupervision,
                      finishedCase: province.totalFinishedSupervision,
                      onTap: () {
                        showGetBottomSheet(
                          buildBottomSheet(
                            LocaleKeys.pdp_title.tr,
                            LocaleKeys.pdp_description.tr,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TotalTestCard(
                      total: totalTests,
                      onPressed: () {
                        Get.toNamed(
                          Routes.testDetail,
                          arguments: {'tests': tests},
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ListTile(
                      onTap: () {
                        Get.toNamed(Routes.nationalDetail);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      tileColor: Colors.grey.shade50,
                      leading: Text(
                        LocaleKeys.national_case_label.tr,
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.nationalDetail);
                        },
                        icon: Icon(
                          Iconsax.arrow_right_14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ListTile(
                      onTap: () {
                        Get.toNamed(Routes.regencyDetail);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      tileColor: Colors.grey.shade50,
                      leading: Text(
                        LocaleKeys.regency_case_label.tr,
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.regencyDetail);
                        },
                        icon: Icon(
                          Iconsax.arrow_right_14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
