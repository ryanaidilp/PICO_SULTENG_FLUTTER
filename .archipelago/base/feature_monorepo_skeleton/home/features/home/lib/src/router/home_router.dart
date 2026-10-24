import 'package:dependencies/auto_route.dart';
import 'package:home/src/presentation/home_shell_page.dart';
import 'package:home/src/presentation/ui/pages/home_page.dart';

part 'home_router.gr.dart';

/// Router configuration for Home feature.
@AutoRouterConfig()
class HomeRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeShellRoute.page,
      path: '/home',
      children: [AutoRoute(page: HomeRoute.page, path: '', initial: true)],
    ),
  ];
}
