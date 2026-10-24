import 'package:dependencies/auto_route.dart';

/// Registry for collecting feature routes before app initialization.
///
/// Features register their routes during pre-launch initialization,
/// before the app router is created. Once the router is built,
/// the registry is locked to prevent modifications.
abstract class RouteRegistry() {
  /// Register routes from a feature.
  ///
  /// Throws [StateError] if called after [lock].
  void register(List<AutoRoute> routes);

  /// Get all registered routes.
  List<AutoRoute> get routes;

  /// Check if registry is locked (after app router is built).
  bool get isLocked;

  /// Lock the registry to prevent further modifications.
  void lock();
}
