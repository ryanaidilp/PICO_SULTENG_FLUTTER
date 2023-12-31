import 'package:dependencies/dependencies.dart';
import 'package:home/home.dart';

part 'pico_router.gr.dart';

@AutoRouterConfig(
  modules: [
    HomeRouter,
  ],
)
class PicoRouter extends _$PicoRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: HomeRoute.page,
          path: '/home',
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
      ];
}
