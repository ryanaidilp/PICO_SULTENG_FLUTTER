import 'package:feature_sdk/feature_sdk.dart';
import 'package:router_registry/router_registry.dart';
import 'package:vaksin/src/router/vaksin_router.dart';

/// What the Vaksin feature declares before the first
/// frame: its routes.
///
/// Const and dependency-free. Never resolve from GetIt in the constructor,
/// [isEnabled] or [registerRoutes]: the host builds every manifest at boot.
/// A route that needs a collaborator (a guard) takes a provider closure.
class const VaksinManifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(VaksinRouter().routes);
  }
}
