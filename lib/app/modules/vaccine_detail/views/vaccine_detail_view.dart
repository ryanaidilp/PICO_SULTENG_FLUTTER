import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_vaccine.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_target_card.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

import '../controllers/vaccine_detail_controller.dart';

class VaccineDetailView extends GetView<VaccineDetailController> {
  final ProvinceVaccine provinceVaccine =
      Get.arguments['province_vaccine'] as ProvinceVaccine;

  final publicColor = Colors.pink.shade400;
  final elderlyColor = Colors.blueAccent;
  final teenagerColor = Colors.pinkAccent.shade100;
  final allVaccineColor = Colors.green.shade700;
  final publicWorkerColor = Colors.purple;
  final healthWorkerColor = Colors.orange.shade700;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () => Scaffold(
          appBar: AppBar(
            title: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: controller.scrollOffset.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.vaccine_label.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      buildUpdatedAtText(
                        provinceVaccine.updatedAt,
                      ),
                      style: const TextStyle(
                        fontSize: 14.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              controller: controller.scrollController,
              shrinkWrap: true,
              children: [
                Text(
                  LocaleKeys.vaccine_label.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(buildUpdatedAtText(provinceVaccine.updatedAt)),
                const SizedBox(height: 6.0),
                const LineContainer(),
                const SizedBox(height: 6.0),
                Text(
                  LocaleKeys.vaccine_type_target.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                LimitedBox(
                  maxHeight: 120,
                  child: CarouselSlider(
                    items: [
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.totalTarget,
                          label: LocaleKeys.vaccine_type_target.tr,
                          color: allVaccineColor,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.elderlyTarget,
                          label:
                              '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_elderly.tr}',
                          color: elderlyColor,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.publicWorkerTarget,
                          label:
                              '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public_worker.tr}',
                          color: publicWorkerColor,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.healthWorkerTarget,
                          label:
                              '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_health_worker.tr}',
                          color: healthWorkerColor,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.publicTarget,
                          label:
                              '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public.tr}',
                          color: publicColor,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: VaccineTargetCard(
                          total: provinceVaccine.teenagerTarget,
                          label:
                              '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_teenager.tr}',
                          color: teenagerColor,
                        ),
                      ),
                    ],
                    options: CarouselOptions(
                      autoPlay: true,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: true,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                const LineContainer(),
                const SizedBox(height: 6.0),
                const Text(
                  'Progress Vaksinasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  height: 25.0,
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: Colors.blueAccent,
                    controller: controller.tabController,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: Get.height * 0.04,
                      indicatorColor: Colors.blueAccent,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                    ),
                    tabs: [
                      Tab(text: LocaleKeys.vaccine_type_first.tr),
                      Tab(text: LocaleKeys.vaccine_type_second.tr),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                LimitedBox(
                  maxHeight: 1280,
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      Column(
                        children: [
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_first.tr,
                            color: allVaccineColor,
                            progress: provinceVaccine.totalFirstCumulative,
                            total: provinceVaccine.totalTarget,
                            newCase: provinceVaccine.totalFirstNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_elderly.tr,
                            color: elderlyColor,
                            progress: provinceVaccine.elderlyFirstCumulative,
                            total: provinceVaccine.elderlyTarget,
                            newCase: provinceVaccine.elderlyFirstNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_public_worker.tr,
                            color: publicWorkerColor,
                            progress:
                                provinceVaccine.publicWorkerFirstCumulative,
                            total: provinceVaccine.publicWorkerTarget,
                            newCase: provinceVaccine.publicWorkerFirstNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_health_worker.tr,
                            color: healthWorkerColor,
                            progress:
                                provinceVaccine.healthWorkerFirstCumulative,
                            total: provinceVaccine.healthWorkerTarget,
                            newCase: provinceVaccine.healthWorkerFirstNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_public.tr,
                            color: publicColor,
                            progress: provinceVaccine.publicFirstCumulative,
                            total: provinceVaccine.publicTarget,
                            newCase: provinceVaccine.publicFirstNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_teenager.tr,
                            color: teenagerColor,
                            progress: provinceVaccine.teenagerFirstCumulative,
                            total: provinceVaccine.teenagerTarget,
                            newCase: provinceVaccine.teenagerFirstNew,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_second.tr,
                            color: allVaccineColor,
                            progress: provinceVaccine.totalSecondCumulative,
                            total: provinceVaccine.totalTarget,
                            newCase: provinceVaccine.totalSecondNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_elderly.tr,
                            color: elderlyColor,
                            progress: provinceVaccine.elderlySecondCumulative,
                            total: provinceVaccine.elderlyTarget,
                            newCase: provinceVaccine.elderlySecondNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_public_worker.tr,
                            color: publicWorkerColor,
                            progress:
                                provinceVaccine.publicWorkerSecondCumulative,
                            total: provinceVaccine.publicWorkerTarget,
                            newCase: provinceVaccine.publicWorkerSecondNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_health_worker.tr,
                            color: healthWorkerColor,
                            progress:
                                provinceVaccine.healthWorkerSecondCumulative,
                            total: provinceVaccine.healthWorkerTarget,
                            newCase: provinceVaccine.healthWorkerSecondNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_public.tr,
                            color: publicColor,
                            progress: provinceVaccine.publicSecondCumulative,
                            total: provinceVaccine.publicTarget,
                            newCase: provinceVaccine.publicSecondNew,
                          ),
                          const SizedBox(height: 6.0),
                          VaccineCard(
                            title: LocaleKeys.vaccine_type_teenager.tr,
                            color: teenagerColor,
                            progress: provinceVaccine.teenagerSecondCumulative,
                            total: provinceVaccine.teenagerTarget,
                            newCase: provinceVaccine.teenagerSecondNew,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
