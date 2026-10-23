import 'package:dependencies/auto_route.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:router_registry/router_registry.dart';

part 'app_router.gr.dart';

/// Main app router that combines routes from all feature manifests.
///
/// Routes are registered dynamically via the [RouteRegistry] during pre-launch
/// initialization. Each feature manifest registers its routes before the app
/// starts.
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: getIt<AppRouter>().config(),
/// )
/// ```
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter(final RouteRegistry _registry) extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    // Feature routes registered via RouteRegistry.
    // Initial route is determined by deepLinkBuilder based on app state.
    ..._registry.routes,
  ];

  /// Returns the initial path based on app state.
  ///
  /// Resolved from registered features' [InitialPathClaim]s — the router
  /// knows no feature types. Add a starter feature (or your own) and it
  /// takes part automatically; no router edits needed.
  String get initialPath => FeatureSDKRegistry.instance.resolveInitialPath();
}
