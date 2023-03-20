import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pico_sulteng_flutter/app/data/models/article.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

class ArticlesController extends GetxController {
  late ApiProvider provider;
  RxInt pageSize = 20.obs;
  RxInt currentPage = 1.obs;
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();

  late PagingController<int, Article> pagingController;

  @override
  void onInit() {
    super.onInit();
    provider = GetInstance().find<ApiProvider>();
    scrollController.addListener(checkIfScrolled);
    pagingController = PagingController(firstPageKey: 1)
      ..addPageRequestListener((pageKey) {
        loadArticles(pageKey);
      });
  }

  Widget? buildFAB() {
    if (scrollOffset.value > 0) {
      return FloatingActionButton(
        onPressed: () {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
        elevation: 10.0,
        backgroundColor: Colors.blueAccent,
        child: const Icon(LineIcons.alternateLongArrowUp),
      );
    }
    return null;
  }

  Future<void> loadArticles(int page) async {
    currentPage++;
    try {
      final data = await provider.loadArticles(page);
      final isLastPage =
          data.length < currentPage.value || currentPage.value >= 6;

      if (isLastPage) {
        pagingController.appendLastPage(data);
      } else {
        pagingController.appendPage(data, currentPage.value);
      }
    } catch (e) {
      pagingController.error = e.toString();
    }
  }

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }


  @override
  void onClose() {
    scrollController.dispose();
    pagingController.dispose();
    super.onClose();
  }
}
