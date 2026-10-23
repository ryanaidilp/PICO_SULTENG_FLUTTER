import 'package:dependencies/auto_route.dart';
import 'package:dependencies/di.dart';

import 'package:router_registry/src/route_registry.dart';

/// Default implementation of [RouteRegistry].
@LazySingleton(as: RouteRegistry)
class RouteRegistryImpl() implements RouteRegistry {
  final List<AutoRoute> _routes = [];
  bool _isLocked = false;

  @override
  void register(List<AutoRoute> routes) {
    if (_isLocked) {
      throw StateError(
        'RouteRegistry is locked. '
        'Routes must be registered before app initialization.',
      );
    }
    _routes.addAll(routes);
  }

  @override
  List<AutoRoute> get routes => List.unmodifiable(_routes);

  @override
  bool get isLocked => _isLocked;

  @override
  void lock() => _isLocked = true;
}
