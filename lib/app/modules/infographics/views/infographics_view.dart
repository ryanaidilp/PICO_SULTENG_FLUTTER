import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/infographic_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/modules/infographics/controllers/infographics_controller.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class InfographicsView extends GetView<InfographicsController> {
  // final List<Infographic> infographics =
  //     Get.arguments['infographics'] as List<Infographic>;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              LocaleKeys.infographic_label.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          floatingActionButton: controller.buildFAB(),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LocaleKeys.infographic_subtitle.tr),
                    const SizedBox(height: 6.0),
                  ],
                ),
              ),
              const LineContainer(),
              Expanded(
                child: Scrollbar(
                  thickness: 6.0,
                  radius: const Radius.circular(10.0),
                  interactive: true,
                  controller: controller.scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: PagedListView.separated(
                      scrollController: controller.scrollController,
                      shrinkWrap: true,
                      pagingController: controller.pagingController,
                      builderDelegate: PagedChildBuilderDelegate(
                        itemBuilder: (_, infographic, index) {
                          return GestureDetector(
                            onTap: () {
                              Get.toNamed(Routes.detailInfographic, arguments: {
                                'infographic': infographic,
                              },);
                            },
                            child: InfographicCard(
                                infographic: infographic! as Infographic,),
                          );
                        },
                        firstPageErrorIndicatorBuilder: (_) {
                          return ErrorPlaceHolderWidget(
                            label:
                                'Terjadi kesalahan saat memuat data! Harap coba lagi!',
                            onRetry: () {
                              controller.pagingController.refresh();
                            },
                          );
                        },
                        newPageErrorIndicatorBuilder: (_) {
                          return ErrorPlaceHolderWidget(
                            label:
                                'Terjadi kesalahan saat memuat data! Harap coba lagi!',
                            onRetry: () {
                              controller.pagingController
                                  .retryLastFailedRequest();
                            },
                          );
                        },
                        firstPageProgressIndicatorBuilder: (_) {
                          return SizedBox(
                            height: Get.height * 0.8,
                            child: const Center(
                                child: SpinKitFadingCircle(color: Colors.blue),),
                          );
                        },
                        newPageProgressIndicatorBuilder: (_) {
                          return const SpinKitFadingCircle(color: Colors.blue);
                        },
                        animateTransitions: true,
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                      separatorBuilder: (_, index) {
                        return const SizedBox(height: 10.0);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
