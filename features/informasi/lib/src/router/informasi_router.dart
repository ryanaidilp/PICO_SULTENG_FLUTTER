import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:identifiers/identifiers.dart';
import 'package:informasi/src/presentation/informasi_shell_page.dart';
import 'package:informasi/src/presentation/ui/pages/informasi_page.dart';
import 'package:informasi/src/presentation/ui/pages/tip_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

part 'informasi_router.gr.dart';

/// Router configuration for Informasi feature.
@AutoRouterConfig()
class InformasiRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: InformasiShellRoute.page,
      path: PicoRoutes.info,
      children: [
        AutoRoute(page: InformasiRoute.page, path: '', initial: true),
        AutoRoute(page: TipRoute.page, path: 'tips/:slug'),
      ],
    ),
  ];
}
