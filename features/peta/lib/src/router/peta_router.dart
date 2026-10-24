import 'package:dependencies/auto_route.dart';
import 'package:peta/src/presentation/peta_shell_page.dart';
import 'package:peta/src/presentation/ui/pages/peta_page.dart';

part 'peta_router.gr.dart';

/// Router configuration for Peta feature.
@AutoRouterConfig()
class PetaRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PetaShellRoute.page,
      path: '/peta',
      children: [AutoRoute(page: PetaRoute.page, path: '', initial: true)],
    ),
  ];
}
