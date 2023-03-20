import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_sulteng_flutter/app/core/theme/color_theme.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/shimmer_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/vaccine_target_card.dart';
import 'package:pico_sulteng_flutter/app/modules/national_vaccine/controllers/national_vaccine_controller.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class NationalVaccineView extends GetView<NationalVaccineController> {
  const NationalVaccineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: controller.scrollOffset.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.vaccine_label_national.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6.0),
                buildUpdatedAtHeader(),
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
              children: [
                Text(
                  LocaleKeys.vaccine_label_national.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                buildUpdatedAt(),
                const SizedBox(height: 6.0),
                const LineContainer(),
                const SizedBox(height: 6.0),
                Lottie.asset('assets/lottie/vaccinated_national.json'),
                const SizedBox(height: 6.0),
                Text(
                  LocaleKeys.vaccine_desc.tr,
                  textAlign: TextAlign.justify,
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
                buildVaccinationTargetSection(),
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
                buildTabBar(),
                const SizedBox(height: 16.0),
                buildVaccineProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildVaccineProgress() {
    if (controller.vaccineLoading.value) {
      return Column(
        children: [
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
          const SizedBox(height: 16.0),
        ],
      );
    }
    if (controller.vaccineError.value) {
      return const SizedBox();
    }
    final vaccine = controller.vaccine;
    return LimitedBox(
      maxHeight: Get.height * 1.75,
      child: TabBarView(
        controller: controller.tabController,
        children: [
          Column(
            children: [
              VaccineCard(
                title: LocaleKeys.vaccine_type_first.tr,
                color: kVaccineColorAll,
                progress: vaccine.totalFirstCumulative,
                total: vaccine.totalTarget,
                newCase: vaccine.totalFirstNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_elderly.tr,
                color: kVaccineColorElderly,
                progress: vaccine.elderlyFirstCumulative,
                total: vaccine.elderlyTarget,
                newCase: vaccine.elderlyFirstNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_public_worker.tr,
                color: kVaccineColorPublicWorker,
                progress: vaccine.publicWorkerFirstCumulative,
                total: vaccine.publicWorkerTarget,
                newCase: vaccine.publicWorkerFirstNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_health_worker.tr,
                color: kVaccineColorHealthWorker,
                progress: vaccine.healthWorkerFirstCumulative,
                total: vaccine.healthWorkerTarget,
                newCase: vaccine.healthWorkerFirstNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_public.tr,
                color: kVaccineColorPublic,
                progress: vaccine.publicFirstCumulative,
                total: vaccine.publicTarget,
                newCase: vaccine.publicFirstNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_teenager.tr,
                color: kVaccineColorTeenager,
                progress: vaccine.teenagerFirstCumulative,
                total: vaccine.teenagerTarget,
                newCase: vaccine.teenagerFirstNew,
              ),
            ],
          ),
          Column(
            children: [
              VaccineCard(
                title: LocaleKeys.vaccine_type_second.tr,
                color: kVaccineColorAll,
                progress: vaccine.totalSecondCumulative,
                total: vaccine.totalTarget,
                newCase: vaccine.totalSecondNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_elderly.tr,
                color: kVaccineColorElderly,
                progress: vaccine.elderlySecondCumulative,
                total: vaccine.elderlyTarget,
                newCase: vaccine.elderlySecondNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_public_worker.tr,
                color: kVaccineColorPublicWorker,
                progress: vaccine.publicWorkerSecondCumulative,
                total: vaccine.publicWorkerTarget,
                newCase: vaccine.publicWorkerSecondNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_health_worker.tr,
                color: kVaccineColorHealthWorker,
                progress: vaccine.healthWorkerSecondCumulative,
                total: vaccine.healthWorkerTarget,
                newCase: vaccine.healthWorkerSecondNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_public.tr,
                color: kVaccineColorPublic,
                progress: vaccine.publicSecondCumulative,
                total: vaccine.publicTarget,
                newCase: vaccine.publicSecondNew,
              ),
              const SizedBox(height: 6.0),
              VaccineCard(
                title: LocaleKeys.vaccine_type_teenager.tr,
                color: kVaccineColorTeenager,
                progress: vaccine.teenagerSecondCumulative,
                total: vaccine.teenagerTarget,
                newCase: vaccine.teenagerSecondNew,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTabBar() {
    if (controller.vaccineLoading.value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerWidget(
            width: Get.width * 0.4,
            height: 30.0,
            highlightColor: Colors.blue.shade50,
          ),
          ShimmerWidget(
            width: Get.width * 0.4,
            height: 30.0,
            highlightColor: Colors.blue.shade50,
          ),
        ],
      );
    }

    if (controller.vaccineError.value) {
      return const SizedBox();
    }

    return SizedBox(
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
    );
  }

  Widget buildVaccinationTargetSection() {
    if (controller.vaccineLoading.value) {
      return Column(
        children: [
          ShimmerWidget(
            width: Get.width * 0.9,
            height: 120.0,
          ),
        ],
      );
    }

    if (controller.vaccineError.value) {
      return ErrorPlaceHolderWidget(
        label: controller.errorMsg.value,
        onRetry: () {
          controller.loadNationalVaccine();
        },
      );
    }

    final vaccine = controller.vaccine;

    return LimitedBox(
      maxHeight: 120,
      child: CarouselSlider(
        items: [
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.totalTarget,
              label: LocaleKeys.vaccine_type_target.tr,
              color: kVaccineColorAll,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.elderlyTarget,
              label:
                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_elderly.tr}',
              color: kVaccineColorElderly,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.publicWorkerTarget,
              label:
                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public_worker.tr}',
              color: kVaccineColorPublicWorker,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.healthWorkerTarget,
              label:
                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_health_worker.tr}',
              color: kVaccineColorHealthWorker,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.publicTarget,
              label:
                  '${LocaleKeys.vaccine_type_target.tr} ${LocaleKeys.vaccine_type_public.tr}',
              color: kVaccineColorPublic,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: VaccineTargetCard(
              total: vaccine.teenagerTarget,
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
        ),
      ),
    );
  }

  Widget buildUpdatedAt() {
    if (controller.vaccineLoading.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: Get.width * 0.3,
            height: 15.0,
          ),
        ],
      );
    }

    if (controller.vaccineError.value) {
      return const SizedBox();
    }

    final vaccine = controller.vaccine;

    return Text(buildUpdatedAtText(vaccine.updatedAt));
  }

  Widget buildUpdatedAtHeader() {
    if (controller.vaccineLoading.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: Get.width * 0.3,
            height: 15.0,
          ),
        ],
      );
    }

    if (controller.vaccineError.value) {
      return const SizedBox();
    }

    final vaccine = controller.vaccine;

    return Text(
      buildUpdatedAtText(
        vaccine.updatedAt,
      ),
      style: const TextStyle(
        fontSize: 14.0,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
