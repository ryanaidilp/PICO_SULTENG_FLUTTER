import 'package:core/src/router/wrapper/empty_router_page.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/home.dart';
import 'package:statistic/statistic.dart';

part 'pico_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
  modules: [
    HomeRouter,
    StatisticRouter,
  ],
)
class PicoRouter extends _$PicoRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: EmptyRouterRoute.page,
          path: '/',
          children: [
            AutoRoute(
              page: HomeRoute.page,
              path: 'home',
              initial: true,
              children: [
                AutoRoute(
                  page: LatestUpdateRoute.page,
                  path: 'latest-update',
                  initial: true,
                ),
                AutoRoute(
                  page: InformationRoute.page,
                  path: 'information',
                ),
              ],
            ),
            AutoRoute(
              page: StatisticRoute.page,
              path: 'statistic',
            ),
          ],
        ),
      ];
}
