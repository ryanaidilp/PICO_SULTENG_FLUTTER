import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/data/provider/api_provider.dart';

class InfographicsController extends GetxController
    with SingleGetTickerProviderMixin {
  late ApiProvider provider;
  RxDouble scrollOffset = 0.0.obs;
  ScrollController scrollController = ScrollController();
  RxInt pageSize = 10.obs;
  RxInt currentPage = 1.obs;
  RxString errorMessage = ''.obs;

  late PagingController<int, Infographic> pagingController;

  void checkIfScrolled() {
    if (scrollController.hasClients) {
      scrollOffset.value = scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  Widget? buildFAB() {
    if (scrollOffset.value > 0) {
      return FloatingActionButton(
        onPressed: () {
          scrollController.animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticIn);
        },
        elevation: 10.0,
        child: const Icon(EvaIcons.arrowCircleUp),
      );
    }

    return null;
  }

  @override
  void onInit() {
    super.onInit();
    provider = GetInstance().find<ApiProvider>();
    scrollController.addListener(checkIfScrolled);
    pagingController = PagingController(firstPageKey: 1)
      ..addPageRequestListener((pageKey) {
        loadInfographics(pageKey);
      });
  }

  Future<void> loadInfographics(int page) async {
    currentPage++;
    try {
      final data = await provider.loadInfographics(page);
      final isLastPage = data.length < pageSize.value;

      if (isLastPage) {
        pagingController.appendLastPage(data);
      } else {
        pagingController.appendPage(data, currentPage.value);
      }
    } catch (e) {
      pagingController.error = e.toString();
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    scrollController.dispose();
    pagingController.dispose();
    super.onClose();
  }
}
