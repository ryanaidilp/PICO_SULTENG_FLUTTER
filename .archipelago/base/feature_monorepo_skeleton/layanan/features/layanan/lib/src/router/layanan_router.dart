import 'package:dependencies/auto_route.dart';
import 'package:layanan/src/presentation/layanan_shell_page.dart';
import 'package:layanan/src/presentation/ui/pages/layanan_page.dart';

part 'layanan_router.gr.dart';

/// Router configuration for Layanan feature.
@AutoRouterConfig()
class LayananRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: LayananShellRoute.page,
      path: '/layanan',
      children: [AutoRoute(page: LayananRoute.page, path: '', initial: true)],
    ),
  ];
}
