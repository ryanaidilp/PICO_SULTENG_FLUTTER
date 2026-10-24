import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:identifiers/identifiers.dart';
import 'package:infografis/src/presentation/infografis_shell_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_detail_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_page.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

part 'infografis_router.gr.dart';

/// Router configuration for Infografis feature.
@AutoRouterConfig()
class InfografisRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: InfografisShellRoute.page,
      path: PicoRoutes.infografis,
      children: [
        AutoRoute(page: InfografisRoute.page, path: '', initial: true),
        AutoRoute(page: InfografisDetailRoute.page, path: ':id'),
      ],
    ),
  ];
}
