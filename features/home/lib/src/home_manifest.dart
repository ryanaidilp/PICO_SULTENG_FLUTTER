import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:home/src/router/home_router.dart';
import 'package:identifiers/identifiers.dart';
import 'package:router_registry/router_registry.dart';

/// What the Home feature declares before the first
/// frame: its routes.
///
/// Const and dependency-free. Never resolve from GetIt in the constructor,
/// [isEnabled] or [registerRoutes]: the host builds every manifest at boot.
/// A route that needs a collaborator (a guard) takes a provider closure.
class const HomeManifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register([
      AutoRoute(
        page: HomeShellRoute.page,
        path: PicoRoutes.beranda,
        children: [AutoRoute(page: HomeRoute.page, path: '', initial: true)],
      ),
    ]);
  }
}
