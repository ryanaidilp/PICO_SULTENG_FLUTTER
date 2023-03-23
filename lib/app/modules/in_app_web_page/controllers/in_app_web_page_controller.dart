import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class InAppWebPageController extends GetxController {
  final GlobalKey webViewKey = GlobalKey();
  RxString webTitle = ''.obs;
  RxString webUrl = ''.obs;
  RxBool isLoading = true.obs;
  late InAppWebViewController webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  URLRequest openInAppBrowser(String link) {
    final Uri url = Uri.parse(link);
    return URLRequest(url: url);
  }

  Future<void> getWebInformation() async {
    final title = await webViewController.getTitle();
    webTitle.value = title ?? '';
    final url = await webViewController.getUrl();
    webUrl.value = url.toString();
  }

  void initializeWebController(InAppWebViewController controller) {
    webViewController = controller;
    getWebInformation();
  }



}
