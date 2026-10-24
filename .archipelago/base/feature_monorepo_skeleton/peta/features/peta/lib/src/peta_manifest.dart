import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:peta/src/router/peta_router.dart';
import 'package:router_registry/router_registry.dart';

/// What the Peta feature declares before the first
/// frame: its routes.
///
/// Const and dependency-free. Never resolve from GetIt in the constructor,
/// [isEnabled] or [registerRoutes]: the host builds every manifest at boot.
/// A route that needs a collaborator (a guard) takes a provider closure.
class const PetaManifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register([
      AutoRoute(
        page: PetaShellRoute.page,
        path: '/peta',
        children: [
          AutoRoute(page: PetaRoute.page, path: '', initial: true),
          // TODO(user): Register more child routes for this feature, e.g.
          //   AutoRoute(page: PetaDetailRoute.page, path: 'detail/:id'),
        ],
      ),
    ]);
  }
}
