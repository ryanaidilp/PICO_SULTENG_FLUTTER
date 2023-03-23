import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_sulteng_flutter/app/core/theme/color_theme.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_target_card.dart';
import 'package:pico_sulteng_flutter/app/modules/vaccine_detail/controllers/vaccine_detail_controller.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class VaccineDetailView extends GetView<VaccineDetailController> {
  const VaccineDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () {
          final provinceVaccine = controller.provinceVaccine;
          return Scaffold(
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
                ),
              ),
            ),
            body: Scrollbar(
              thickness: 6.0,
              radius: const Radius.circular(10.0),
              interactive: true,
              controller: controller.scrollController,
              child: Padding(
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
                    Lottie.asset('assets/lottie/vaccinated.json'),
                    const SizedBox(height: 6.0),
                    Text(
                      LocaleKeys.vaccine_desc.tr,
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 6.0),
                    ListTile(
                      onTap: () {
                        Get.toNamed(Routes.nationalVaccine.tr);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      tileColor: Colors.grey.shade50,
                      leading: Text(
                        LocaleKeys.vaccine_label_national.tr,
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.nationalVaccine.tr);
                        },
                        icon: Icon(
                          Iconsax.arrow_right_14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
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
                    Expanded(
                      child: CarouselSlider(
                        items: [
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.totalTarget,
                              label: LocaleKeys.vaccine_type_target.tr,
                              color: kVaccineColorAll,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.elderlyTarget,
                              label:
                                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_elderly.tr}',
                              color: kVaccineColorElderly,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.publicWorkerTarget,
                              label:
                                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public_worker.tr}',
                              color: kVaccineColorPublicWorker,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.healthWorkerTarget,
                              label:
                                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_health_worker.tr}',
                              color: kVaccineColorHealthWorker,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.publicTarget,
                              label:
                                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public.tr}',
                              color: kVaccineColorPublic,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: VaccineTargetCard(
                              total: provinceVaccine.teenagerTarget,
                              label:
                                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_teenager.tr}',
                              color: kVaccineColorTeenager,
                            ),
                          ),
                        ],
                        options: CarouselOptions(
                          autoPlay: true,
                          enableInfiniteScroll: false,
                          enlargeCenterPage: true,
                          height: Get.height * 0.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const LineContainer(),
                    const SizedBox(height: 6.0),
                    Text(
                      LocaleKeys.vaccine_card_vaccine_progress.tr,
                      style: const TextStyle(
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
                      maxHeight: Get.height * 1.7,
                      child: TabBarView(
                        controller: controller.tabController,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_first.tr,
                                color: kVaccineColorAll,
                                progress: provinceVaccine.totalFirstCumulative,
                                total: provinceVaccine.totalTarget,
                                newCase: provinceVaccine.totalFirstNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_elderly.tr,
                                color: kVaccineColorElderly,
                                progress:
                                    provinceVaccine.elderlyFirstCumulative,
                                total: provinceVaccine.elderlyTarget,
                                newCase: provinceVaccine.elderlyFirstNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_public_worker.tr,
                                color: kVaccineColorPublicWorker,
                                progress:
                                    provinceVaccine.publicWorkerFirstCumulative,
                                total: provinceVaccine.publicWorkerTarget,
                                newCase: provinceVaccine.publicWorkerFirstNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_health_worker.tr,
                                color: kVaccineColorHealthWorker,
                                progress:
                                    provinceVaccine.healthWorkerFirstCumulative,
                                total: provinceVaccine.healthWorkerTarget,
                                newCase: provinceVaccine.healthWorkerFirstNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_public.tr,
                                color: kVaccineColorPublic,
                                progress: provinceVaccine.publicFirstCumulative,
                                total: provinceVaccine.publicTarget,
                                newCase: provinceVaccine.publicFirstNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_teenager.tr,
                                color: kVaccineColorTeenager,
                                progress:
                                    provinceVaccine.teenagerFirstCumulative,
                                total: provinceVaccine.teenagerTarget,
                                newCase: provinceVaccine.teenagerFirstNew,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_second.tr,
                                color: kVaccineColorAll,
                                progress: provinceVaccine.totalSecondCumulative,
                                total: provinceVaccine.totalTarget,
                                newCase: provinceVaccine.totalSecondNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_elderly.tr,
                                color: kVaccineColorElderly,
                                progress:
                                    provinceVaccine.elderlySecondCumulative,
                                total: provinceVaccine.elderlyTarget,
                                newCase: provinceVaccine.elderlySecondNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_public_worker.tr,
                                color: kVaccineColorPublicWorker,
                                progress: provinceVaccine
                                    .publicWorkerSecondCumulative,
                                total: provinceVaccine.publicWorkerTarget,
                                newCase: provinceVaccine.publicWorkerSecondNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_health_worker.tr,
                                color: kVaccineColorHealthWorker,
                                progress: provinceVaccine
                                    .healthWorkerSecondCumulative,
                                total: provinceVaccine.healthWorkerTarget,
                                newCase: provinceVaccine.healthWorkerSecondNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_public.tr,
                                color: kVaccineColorPublic,
                                progress:
                                    provinceVaccine.publicSecondCumulative,
                                total: provinceVaccine.publicTarget,
                                newCase: provinceVaccine.publicSecondNew,
                              ),
                              const SizedBox(height: 6.0),
                              VaccineCard(
                                title: LocaleKeys.vaccine_type_teenager.tr,
                                color: kVaccineColorTeenager,
                                progress:
                                    provinceVaccine.teenagerSecondCumulative,
                                total: provinceVaccine.teenagerTarget,
                                newCase: provinceVaccine.teenagerSecondNew,
                              ),
                            ],
                          ),
                        ],
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
