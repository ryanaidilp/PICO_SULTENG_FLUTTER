import 'package:dependencies/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:router_registry/src/route_registry_impl.dart';

void main() {
  late RouteRegistryImpl registry;

  setUp(() {
    registry = RouteRegistryImpl();
  });

  group('RouteRegistryImpl', () {
    test('starts unlocked', () {
      expect(registry.isLocked, isFalse);
    });

    test('starts with empty routes', () {
      expect(registry.routes, isEmpty);
    });

    test('register adds routes', () {
      final routes = [
        AutoRoute(
          page: PageInfo(
            'TestPage',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
      ];

      registry.register(routes);

      expect(registry.routes, hasLength(1));
    });

    test('register adds multiple batches of routes', () {
      final routes1 = [
        AutoRoute(
          page: PageInfo(
            'Page1',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
      ];
      final routes2 = [
        AutoRoute(
          page: PageInfo(
            'Page2',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
        AutoRoute(
          page: PageInfo(
            'Page3',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
      ];

      registry
        ..register(routes1)
        ..register(routes2);

      expect(registry.routes, hasLength(3));
    });

    test('lock sets isLocked to true', () {
      registry.lock();

      expect(registry.isLocked, isTrue);
    });

    test('throws StateError when registering after lock', () {
      registry.lock();

      expect(
        () => registry.register([
          AutoRoute(
            page: PageInfo(
              'TestPage',
              builder: (data) => throw UnimplementedError(),
            ),
          ),
        ]),
        throwsStateError,
      );
    });

    test('routes returns unmodifiable list', () {
      registry.register([
        AutoRoute(
          page: PageInfo(
            'TestPage',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
      ]);

      final routes = registry.routes;

      expect(
        () => routes.add(
          AutoRoute(
            page: PageInfo(
              'AnotherPage',
              builder: (data) => throw UnimplementedError(),
            ),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('routes are preserved after lock', () {
      registry.register([
        AutoRoute(
          page: PageInfo(
            'Page1',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
        AutoRoute(
          page: PageInfo(
            'Page2',
            builder: (data) => throw UnimplementedError(),
          ),
        ),
      ]);

      registry.lock();

      expect(registry.routes, hasLength(2));
    });
  });
}
