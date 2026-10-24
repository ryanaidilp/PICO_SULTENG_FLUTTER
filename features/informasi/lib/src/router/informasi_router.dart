import 'package:dependencies/auto_route.dart';
import 'package:informasi/src/presentation/informasi_shell_page.dart';
import 'package:informasi/src/presentation/ui/pages/informasi_page.dart';

part 'informasi_router.gr.dart';

/// Router configuration for Informasi feature.
@AutoRouterConfig()
class InformasiRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: InformasiShellRoute.page,
      path: '/informasi',
      children: [AutoRoute(page: InformasiRoute.page, path: '', initial: true)],
    ),
  ];
}
