import 'package:dependencies/auto_route.dart';
import 'package:infografis/src/presentation/infografis_shell_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_page.dart';

part 'infografis_router.gr.dart';

/// Router configuration for Infografis feature.
@AutoRouterConfig()
class InfografisRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: InfografisShellRoute.page,
      path: '/infografis',
      children: [
        AutoRoute(page: InfografisRoute.page, path: '', initial: true),
      ],
    ),
  ];
}
