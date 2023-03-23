import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';

class NoInternetController extends GetxController {
  late StreamSubscription<InternetConnectionStatus> status;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 5));
    try {
      status = InternetConnectionChecker()
          .onStatusChange
          .listen((InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
            Get.offNamed(Routes.home);
            break;
          case InternetConnectionStatus.disconnected:
            if (![
              Routes.noInternet,
            ].contains(Get.currentRoute)) {
              Get.offNamed(Routes.noInternet);
            }
            break;
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }


  @override
  void onClose() {
    status.cancel();
    super.onClose();
  }
}
