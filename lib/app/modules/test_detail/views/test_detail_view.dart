import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/card_test_case.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

import '../controllers/test_detail_controller.dart';

class TestDetailView extends GetView<TestDetailController> {
  final List<ProvinceTest> tests = Get.arguments['tests'] as List<ProvinceTest>;

  @override
  Widget build(BuildContext context) {
    final StringBuffer buffer = StringBuffer();
    final tabs = tests.map((test) {
      final texts = test.name.split(' ');
      final title = texts.map((e) => e.substring(0, 1)).toList();
      buffer.writeAll(title);
      final tabLabel = buffer.toString();
      buffer.clear();
      return Tab(
        text: tabLabel,
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.card_case_label_total_test.tr,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          tabs: tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.blueAccent,
          controller: controller.tabController,
          labelStyle: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
          indicator: BubbleTabIndicator(
            indicatorHeight: Get.height * 0.04,
            indicatorColor: Colors.blueAccent,
            tabBarIndicatorSize: TabBarIndicatorSize.tab,
            insets: const EdgeInsets.symmetric(horizontal: 14.0),
            padding:
                const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
          ),
        ),
      ),
      body: Obx(
        () => TabBarView(
          controller: controller.tabController,
          children: tests.map((test) {
            final reactivePercentage = test.positive / test.total;
            final nonReactivePercentage = test.negative / test.total;
            final processPercentage = test.process / test.total;
            final invalidPercentage = test.invalid / test.total;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.updated_at.tr,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      buildUpdatedAtText(test.date),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 16.0,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade100,
                              blurRadius: 10.0,
                              spreadRadius: 3.0,
                              offset: Offset.fromDirection(-30.0, 5.0),
                            )
                          ],
                          borderRadius: BorderRadius.circular(10.0),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange,
                              Colors.orange.shade200,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                controller.testDescriptions[
                                    controller.currentTab.value],
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 10.0,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    LocaleKeys.card_case_label_sample.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                test.sample,
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 10.0,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    LocaleKeys.card_case_label_duration.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                test.duration,
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0.0,
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.test_done.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                numberFormat(test.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28.0,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Wrap(
                      children: [
                        SizedBox(
                          width: Get.width * 0.3,
                          child: CardTestCase(
                            label: LocaleKeys.card_case_label_reactive.tr,
                            count: test.positive,
                            percentage: reactivePercentage,
                          ),
                        ),
                        SizedBox(
                          width: Get.width * 0.3,
                          child: CardTestCase(
                            label: LocaleKeys.card_case_label_non_reactive.tr,
                            count: test.negative,
                            percentage: nonReactivePercentage,
                          ),
                        ),
                        SizedBox(
                          width: Get.width * 0.3,
                          child: CardTestCase(
                            label: LocaleKeys.card_case_label_invalid.tr,
                            count: test.invalid,
                            percentage: invalidPercentage,
                            isInvalid: true,
                          ),
                        ),
                        SizedBox(
                          width: Get.width * 0.3,
                          child: CardTestCase(
                            label: LocaleKeys.card_case_label_process.tr,
                            count: test.process,
                            percentage: processPercentage,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
