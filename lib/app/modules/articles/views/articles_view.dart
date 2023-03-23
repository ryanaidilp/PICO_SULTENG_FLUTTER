import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pico_sulteng_flutter/app/data/models/article.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/article_card.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/error_placeholder_widget.dart';
import 'package:pico_sulteng_flutter/app/global_widgets/line_container.dart';
import 'package:pico_sulteng_flutter/app/modules/articles/controllers/articles_controller.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class ArticlesView extends GetView<ArticlesController> {
  const ArticlesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              LocaleKeys.article.tr,
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
                    Text(LocaleKeys.article_subtitle.tr),
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
                      pagingController: controller.pagingController,
                      shrinkWrap: true,
                      builderDelegate: PagedChildBuilderDelegate(
                        itemBuilder: (_, item, index) {
                          final article = item! as Article;
                          return ArticleCard(article: article);
                        },
                        firstPageErrorIndicatorBuilder: (_) {
                          return ErrorPlaceHolderWidget(
                            label: LocaleKeys.error_article.tr,
                            onRetry: () {
                              controller.pagingController.refresh();
                            },
                          );
                        },
                        newPageErrorIndicatorBuilder: (_) {
                          return ErrorPlaceHolderWidget(
                            label: LocaleKeys.error_article.tr,
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
                        return const SizedBox(height: 8.0);
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
