import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/infographic_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';

import '../controllers/infographics_controller.dart';

class InfographicsView extends GetView<InfographicsController> {
  final List<Infographic> infographics =
      Get.arguments['infographics'] as List<Infographic>;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () => Scaffold(
          appBar: AppBar(
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: controller.scrollOffset.value,
              child: const Text(
                'Info Praktikal',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                  overflow: TextOverflow.ellipsis,
                ),
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
              child: SingleChildScrollView(
                controller: controller.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Info Praktikal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Text('Kumpulan infografis terkait covid-19!'),
                    const SizedBox(height: 6.0),
                    const LineContainer(),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final infographic = infographics[index];
                        return GestureDetector(
                          child: InfographicCard(infographic: infographic),
                          onTap: () {
                            Get.toNamed(
                              Routes.detailInfographic,
                              arguments: {
                                'infographic': infographic,
                              },
                            );
                          },
                        );
                      },
                      shrinkWrap: true,
                      itemCount: infographics.length,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
