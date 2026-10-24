import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:identifiers/identifiers.dart';
import 'package:layanan/src/presentation/layanan_shell_page.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_detail_page.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_list_page.dart';
import 'package:layanan/src/presentation/ui/pages/layanan_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

part 'layanan_router.gr.dart';

/// Router configuration for Layanan feature.
@AutoRouterConfig()
class LayananRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: LayananShellRoute.page,
      path: PicoRoutes.layanan,
      children: [
        AutoRoute(page: LayananRoute.page, path: '', initial: true),
        AutoRoute(page: HospitalListRoute.page, path: 'rumah-sakit'),
        AutoRoute(page: HospitalDetailRoute.page, path: 'rumah-sakit/:code'),
      ],
    ),
  ];
}
