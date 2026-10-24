import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:router_registry/router_registry.dart';
import 'package:statistik/src/router/statistik_router.dart';

/// What the Statistik feature declares before the first
/// frame: its routes.
///
/// Const and dependency-free. Never resolve from GetIt in the constructor,
/// [isEnabled] or [registerRoutes]: the host builds every manifest at boot.
/// A route that needs a collaborator (a guard) takes a provider closure.
class const StatistikManifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register([
      AutoRoute(
        page: StatistikShellRoute.page,
        path: '/statistik',
        children: [
          AutoRoute(page: StatistikRoute.page, path: '', initial: true),
          // TODO(user): Register more child routes for this feature, e.g.
          //   AutoRoute(page: StatistikDetailRoute.page, path: 'detail/:id'),
        ],
      ),
    ]);
  }
}
