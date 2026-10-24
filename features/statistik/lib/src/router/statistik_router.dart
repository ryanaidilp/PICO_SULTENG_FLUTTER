import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:identifiers/identifiers.dart';
import 'package:statistik/src/presentation/statistik_shell_page.dart';
import 'package:statistik/src/presentation/ui/pages/area_page.dart';
import 'package:statistik/src/presentation/ui/pages/kabupaten_page.dart';
import 'package:statistik/src/presentation/ui/pages/rt_page.dart';

part 'statistik_router.gr.dart';

/// Router configuration for Statistik feature.
@AutoRouterConfig()
class StatistikRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: StatistikShellRoute.page,
      path: PicoRoutes.statistikRoot,
      children: [
        // No transition: a control change replaces the route with its new
        // canonical URL and the page must not animate.
        AutoRoute(
          page: AreaRoute.page,
          path: '',
          initial: true,
          type: RouteType.custom(
            transitionsBuilder: TransitionsBuilders.noTransition,
            durationInMilliseconds: 0,
          ),
        ),
        AutoRoute(page: KabupatenRoute.page, path: 'kabupaten'),
        AutoRoute(page: RtRoute.page, path: 'rt'),
        AutoRoute(
          page: RegencyAreaRoute.page,
          path: 'kabupaten/:code',
          type: RouteType.custom(
            transitionsBuilder: TransitionsBuilders.noTransition,
            durationInMilliseconds: 0,
          ),
        ),
        AutoRoute(
          page: ProvinceAreaRoute.page,
          path: 'provinsi/:id',
          type: RouteType.custom(
            transitionsBuilder: TransitionsBuilders.noTransition,
            durationInMilliseconds: 0,
          ),
        ),
      ],
    ),
  ];
}
