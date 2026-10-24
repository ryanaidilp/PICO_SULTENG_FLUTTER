import 'package:dependencies/auto_route.dart';
import 'package:statistik/src/presentation/statistik_shell_page.dart';
import 'package:statistik/src/presentation/ui/pages/statistik_page.dart';

part 'statistik_router.gr.dart';

/// Router configuration for Statistik feature.
@AutoRouterConfig()
class StatistikRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: StatistikShellRoute.page,
      path: '/statistik',
      children: [AutoRoute(page: StatistikRoute.page, path: '', initial: true)],
    ),
  ];
}
