import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_case.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_confirmed.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/shimmer_widget.dart';
import 'package:pico_sulteng_flutter/app/modules/regency_detail/controllers/regency_detail_controller.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class RegencyDetailView extends GetView<RegencyDetailController> {
  const RegencyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.regency_case_label.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: buildTabBar(),
        ),
        body: buildBodySection(),
      ),
    );
  }

  Widget buildBodySection() {
    if (controller.statisticLoading.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LimitedBox(
              maxHeight: 30.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 8.0);
                },
                itemBuilder: (_, __) {
                  return ShimmerWidget(
                    width: 90,
                    height: 25.0,
                    highlightColor: Colors.blue.shade50,
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              LocaleKeys.updated_at.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 8.0),
            const ShimmerWidget(width: 120, height: 10.0),
            const SizedBox(height: 8.0),
            ShimmerWidget(
              width: double.infinity,
              height: 90.0,
              highlightColor: Colors.red.shade50,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                children: [
                  ShimmerWidget(
                    width: double.infinity,
                    height: 90.0,
                    highlightColor: Colors.blue.shade50,
                  ),
                  ShimmerWidget(
                    width: double.infinity,
                    height: 90.0,
                    highlightColor: Colors.green.shade50,
                  ),
                  ShimmerWidget(
                    width: double.infinity,
                    height: 90.0,
                    highlightColor: Colors.orange.shade50,
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    if (controller.statisticError.value) {
      return Center(
        child: ErrorPlaceHolderWidget(
          label: controller.errorMsg.value,
          onRetry: () {
            controller.loadRegencyStatistic();
          },
        ),
      );
    }

    final data = controller.regencyStatistic;
    return TabBarView(
      controller: controller.tabController,
      children: data.map((statistic) {
        return SingleChildScrollView(
          controller: controller.scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.updated_at.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(buildUpdatedAtText(statistic.updatedAt)),
                CardConfirmed(
                  total: statistic.totalPositive,
                  newCase: statistic.newPositive,
                  shadowColor: Colors.red.shade100,
                  startColor: Colors.redAccent,
                  endColor: Colors.red.shade200,
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  children: [
                    SizedBox(
                      width: Get.width * 0.3,
                      child: CardCase(
                        newCase: statistic.newTreatment,
                        total: statistic.totalTreatment,
                        icon: Iconsax.hospital,
                        bgColorIcon: Colors.blue.shade50,
                        colorIcon: Colors.blueAccent,
                        label: LocaleKeys.card_case_label_under_treatment.tr,
                      ),
                    ),
                    SizedBox(
                      width: Get.width * 0.3,
                      child: CardCase(
                        newCase: statistic.newRecovered,
                        total: statistic.totalRecovered,
                        icon: Icons.check_rounded,
                        bgColorIcon: Colors.green.shade50,
                        colorIcon: Colors.green,
                        label: LocaleKeys.card_case_label_recovered.tr,
                      ),
                    ),
                    SizedBox(
                      width: Get.width * 0.3,
                      child: CardCase(
                        newCase: statistic.newDeceased,
                        total: statistic.totalDeceased,
                        icon: Icons.close_rounded,
                        bgColorIcon: Colors.orange.shade50,
                        colorIcon: Colors.orange,
                        label: LocaleKeys.card_case_label_deceased.tr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  PreferredSizeWidget? buildTabBar() {
    if (!controller.checkIfRegencyStatisticLoaded()) {
      return null;
    }

    return TabBar(
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: Colors.blueAccent,
      controller: controller.tabController,
      isScrollable: true,
      labelStyle: const TextStyle(
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.w700,
      ),
      indicator: BubbleTabIndicator(
        indicatorHeight: Get.height * 0.04,
        indicatorColor: Colors.blueAccent,
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
        insets: const EdgeInsets.symmetric(horizontal: 6.0),
        padding: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      ),
      tabs: controller.tabs.map((element) => Tab(text: element)).toList(),
    );
  }
}
