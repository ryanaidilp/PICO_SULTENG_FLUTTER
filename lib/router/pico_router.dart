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
          page: HomeWrapperRoute.page,
          path: '/',
          children: [
            AutoRoute(
              page: HomeRoute.page,
              path: 'home',
              initial: true,
            ),
          ],
        ),
      ];
}
