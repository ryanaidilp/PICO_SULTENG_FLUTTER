import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/controllers/in_app_web_page_controller.dart';

class InAppWebPageView extends GetView<InAppWebPageController> {
  @override
  Widget build(BuildContext context) {
    final String link = Get.arguments['link'] as String;
    final String title = Get.arguments['title'] as String;
    return Obx(
      () => WillPopScope(
        onWillPop: () => _exitApp(context),
        child: CustomScrollView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              leading: IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(Icons.close_rounded),
              ),
              bottom: controller.isLoading.value
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(10.0),
                      child: LinearProgressIndicator(),
                    )
                  : null,
              elevation: 0.0,
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    controller.webUrl.value,
                    style: const TextStyle(
                      fontSize: 12.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: Get.height * 0.9,
                child: InAppWebView(
                  key: controller.webViewKey,
                  initialOptions: controller.options,
                  onWebViewCreated: controller.initializeWebController,
                  initialUrlRequest: controller.openInAppBrowser(link),
                  onProgressChanged: (webController, progress) {
                    if (progress == 100) {
                      controller.isLoading.value = false;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await controller.webViewController.canGoBack()) {
      controller.webViewController.goBack();
    }

    return Future.value(false);
  }
}
