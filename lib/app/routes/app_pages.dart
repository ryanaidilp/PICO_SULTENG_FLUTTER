import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/modules/data_detail/bindings/data_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/data_detail/views/data_detail_view.dart';
import 'package:pico_sulteng_flutter/app/modules/home/bindings/home_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/home/views/home_view.dart';
import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/bindings/in_app_web_page_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/views/in_app_web_page_view.dart';
import 'package:pico_sulteng_flutter/app/modules/no_internet/bindings/no_internet_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/no_internet/views/no_internet_view.dart';
import 'package:pico_sulteng_flutter/app/modules/test_detail/bindings/test_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/test_detail/views/test_detail_view.dart';
import 'package:pico_sulteng_flutter/app/modules/vaccine_detail/bindings/vaccine_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/vaccine_detail/views/vaccine_detail_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.dataDetail,
      page: () => DataDetailView(),
      binding: DataDetailBinding(),
    ),
    GetPage(
      name: _Paths.testDetail,
      page: () => TestDetailView(),
      binding: TestDetailBinding(),
    ),
    GetPage(
      name: _Paths.vaccineDetail,
      page: () => VaccineDetailView(),
      binding: VaccineDetailBinding(),
    ),
    GetPage(
      name: _Paths.noInternet,
      page: () => NoInternetView(),
      binding: NoInternetBinding(),
    ),
    GetPage(
      name: _Paths.inAppWebPage,
      page: () => InAppWebPageView(),
      binding: InAppWebPageBinding(),
    ),
  ];
}
