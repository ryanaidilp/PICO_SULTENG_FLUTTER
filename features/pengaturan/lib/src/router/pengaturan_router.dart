import 'package:dependencies/auto_route.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pengaturan/src/presentation/pengaturan_shell_page.dart';
import 'package:pengaturan/src/presentation/ui/pages/pengaturan_page.dart';

part 'pengaturan_router.gr.dart';

/// Router configuration for Pengaturan feature.
@AutoRouterConfig()
class PengaturanRouter() extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PengaturanShellRoute.page,
      path: PicoRoutes.pengaturan,
      children: [
        AutoRoute(page: PengaturanRoute.page, path: '', initial: true),
      ],
    ),
  ];
}
