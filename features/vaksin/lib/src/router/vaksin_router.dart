import 'package:dependencies/auto_route.dart';
import 'package:identifiers/identifiers.dart';
import 'package:vaksin/src/presentation/ui/pages/vaksin_page.dart';
import 'package:vaksin/src/presentation/vaksin_shell_page.dart';

part 'vaksin_router.gr.dart';

/// Router configuration for Vaksin feature.
@AutoRouterConfig()
class VaksinRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: VaksinShellRoute.page,
      path: PicoRoutes.vaksin,
      children: [AutoRoute(page: VaksinRoute.page, path: '', initial: true)],
    ),
  ];
}
