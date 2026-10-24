import 'package:feature_sdk/feature_sdk.dart';
import 'package:informasi/src/domain/review_markers.dart';
import 'package:informasi/src/router/informasi_router.dart';
import 'package:router_registry/router_registry.dart';

/// What the Informasi feature declares before the first
/// frame: its routes.
///
/// Const and dependency-free. Never resolve from GetIt in the constructor,
/// [isEnabled] or [registerRoutes]: the host builds every manifest at boot.
/// A route that needs a collaborator (a guard) takes a provider closure.
class const InformasiManifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {
    // A release build with content still "Dalam peninjauan" must not boot.
    assertNoOpenReviewMarkers();
    registry.register(InformasiRouter().routes);
  }
}
