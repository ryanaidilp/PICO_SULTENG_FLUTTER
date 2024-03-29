import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/modules/articles/bindings/articles_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/articles/views/articles_view.dart';
import 'package:pico_sulteng_flutter/app/modules/data_detail/bindings/data_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/data_detail/views/data_detail_view.dart';
import 'package:pico_sulteng_flutter/app/modules/detail_infographic/bindings/detail_infographic_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/detail_infographic/views/detail_infographic_view.dart';
import 'package:pico_sulteng_flutter/app/modules/home/bindings/home_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/home/views/home_view.dart';
import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/bindings/in_app_web_page_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/in_app_web_page/views/in_app_web_page_view.dart';
import 'package:pico_sulteng_flutter/app/modules/infographics/bindings/infographics_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/infographics/views/infographics_view.dart';
import 'package:pico_sulteng_flutter/app/modules/national_detail/bindings/national_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/national_detail/views/national_detail_view.dart';
import 'package:pico_sulteng_flutter/app/modules/national_vaccine/bindings/national_vaccine_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/national_vaccine/views/national_vaccine_view.dart';
import 'package:pico_sulteng_flutter/app/modules/no_internet/bindings/no_internet_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/no_internet/views/no_internet_view.dart';
import 'package:pico_sulteng_flutter/app/modules/regency_detail/bindings/regency_detail_binding.dart';
import 'package:pico_sulteng_flutter/app/modules/regency_detail/views/regency_detail_view.dart';
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
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.dataDetail,
      page: () => const DataDetailView(),
      binding: DataDetailBinding(),
    ),
    GetPage(
      name: _Paths.testDetail,
      page: () => const TestDetailView(),
      binding: TestDetailBinding(),
    ),
    GetPage(
      name: _Paths.vaccineDetail,
      page: () => const VaccineDetailView(),
      binding: VaccineDetailBinding(),
    ),
    GetPage(
      name: _Paths.noInternet,
      page: () => const NoInternetView(),
      binding: NoInternetBinding(),
    ),
    GetPage(
      name: _Paths.inAppWebPage,
      page: () => const InAppWebPageView(),
      binding: InAppWebPageBinding(),
    ),
    GetPage(
      name: _Paths.detailInfographic,
      page: () => const DetailInfographicView(),
      binding: DetailInfographicBinding(),
    ),
    GetPage(
      name: _Paths.infographics,
      page: () => const InfographicsView(),
      binding: InfographicsBinding(),
    ),
    GetPage(
      name: _Paths.articles,
      page: () => const ArticlesView(),
      binding: ArticlesBinding(),
    ),
    GetPage(
      name: _Paths.nationalDetail,
      page: () => const NationalDetailView(),
      binding: NationalDetailBinding(),
    ),
    GetPage(
      name: _Paths.regencyDetail,
      page: () => const RegencyDetailView(),
      binding: RegencyDetailBinding(),
    ),
    GetPage(
      name: _Paths.nationalVaccine,
      page: () => const NationalVaccineView(),
      binding: NationalVaccineBinding(),
    ),
  ];
}
