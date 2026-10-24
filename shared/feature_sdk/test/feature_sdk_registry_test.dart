import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:router_registry/router_registry.dart';

class _FakeSDK({
  final bool enabled = true,
  final Map<PageIdentifier, PageConfig> pages = const {},
}) extends FeatureSDK {
  @override
  bool get isEnabled => enabled;

  @override
  Map<PageIdentifier, PageConfig> get pageConfigurations => pages;

  @override
  void registerRoutes(RouteRegistry registry) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> launch(BuildContext context) async {}
}

/// A plain manifest: routes only, no SDK behind it.
class const _Manifest() extends FeatureManifest {
  @override
  void registerRoutes(RouteRegistry registry) {}
}

/// SDK that opts in to initial path resolution via [InitialPathProvider].
class _ClaimingSDK({required final InitialPathClaim claim, super.enabled})
    extends _FakeSDK
    implements InitialPathProvider {
  @override
  InitialPathClaim get initialPathClaim => claim;
}

enum _Page(@override final PageConfig config) implements PageIdentifier {
  home(PageConfig(deeplinkPath: '/home')),
  detail(PageConfig(deeplinkPath: '/detail'));

  @override
  String get name => toString().split('.').last;
}

void main() {
  late FeatureSDKRegistry registry;

  setUp(() {
    registry = FeatureSDKRegistry.instance;
    registry.clear();
  });

  tearDown(() {
    registry.clear();
  });

  group('FeatureSDKRegistry', () {
    test('starts with empty list', () {
      expect(registry.manifests, isEmpty);
    });

    test('register adds SDK to list', () {
      final sdk = _FakeSDK();
      registry.register(sdk);

      expect(registry.manifests, contains(sdk));
      expect(registry.manifests.length, 1);
    });

    test('register multiple SDKs', () {
      final sdk1 = _FakeSDK();
      final sdk2 = _FakeSDK();
      registry.register(sdk1);
      registry.register(sdk2);

      expect(registry.manifests.length, 2);
      expect(registry.manifests, containsAll([sdk1, sdk2]));
    });

    test('register throws StateError on duplicate', () {
      final sdk = _FakeSDK();
      registry.register(sdk);

      expect(() => registry.register(sdk), throwsStateError);
    });

    test('unregister removes SDK from list', () {
      final sdk = _FakeSDK();
      registry.register(sdk);

      registry.unregister(sdk);

      expect(registry.manifests, isEmpty);
    });

    test('unregister non-existent SDK does nothing', () {
      final sdk = _FakeSDK();

      // Should not throw
      registry.unregister(sdk);

      expect(registry.manifests, isEmpty);
    });

    test('clear removes all SDKs', () {
      final sdk1 = _FakeSDK();
      final sdk2 = _FakeSDK();
      registry.register(sdk1);
      registry.register(sdk2);

      registry.clear();

      expect(registry.manifests, isEmpty);
    });

    test('register after seal trips a debug assert; clear unseals', () {
      registry.seal();
      expect(
        () => registry.register(_FakeSDK()),
        throwsA(isA<AssertionError>()),
      );

      registry.clear();
      registry.register(_FakeSDK());
      expect(registry.manifests, hasLength(1));
    });

    test('manifests returns unmodifiable list', () {
      final sdk = _FakeSDK();
      registry.register(sdk);

      final sdks = registry.manifests;

      expect(() => sdks.add(_FakeSDK()), throwsUnsupportedError);
      expect(sdks.clear, throwsUnsupportedError);
    });

    test('instance returns singleton', () {
      final instance1 = FeatureSDKRegistry.instance;
      final instance2 = FeatureSDKRegistry.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('isEnabled defaults to true', () {
      expect(_FakeSDK().isEnabled, isTrue);
    });

    test('pageConfigurations defaults to empty map', () {
      expect(_FakeSDK().pageConfigurations, isEmpty);
    });

    test('a const manifest takes the defaults and registers once', () async {
      const manifest = _Manifest();
      expect(manifest.isEnabled, isTrue);
      expect(manifest.pageConfigurations, isEmpty);
      await manifest.initialize();
      await manifest.dispose();

      registry.register(manifest);
      expect(registry.enabledManifests, [manifest]);
      // Const instances are canonical, so a second registration is a
      // duplicate.
      expect(() => registry.register(const _Manifest()), throwsStateError);
    });

    test('enabledManifests excludes disabled ones', () {
      final enabled = _FakeSDK();
      final disabled = _FakeSDK(enabled: false);
      registry
        ..register(enabled)
        ..register(disabled);

      expect(registry.enabledManifests, [enabled]);
      expect(registry.manifests, hasLength(2));
    });

    test('enabledPageConfigurations aggregates from enabled SDKs only', () {
      final enabled = _FakeSDK(
        pages: const {_Page.home: PageConfig(deeplinkPath: '/home')},
      );
      final disabled = _FakeSDK(
        enabled: false,
        pages: const {_Page.detail: PageConfig(deeplinkPath: '/detail')},
      );
      registry
        ..register(enabled)
        ..register(disabled);

      expect(registry.enabledPageConfigurations, hasLength(1));
      expect(
        registry.enabledPageConfigurations.containsKey(_Page.home),
        isTrue,
      );
      expect(
        registry.enabledPageConfigurations.containsKey(_Page.detail),
        isFalse,
      );
    });

    test('findManifestForPage returns owning enabled SDK', () {
      final owner = _FakeSDK(
        pages: const {_Page.home: PageConfig(deeplinkPath: '/home')},
      );
      registry.register(owner);

      expect(registry.findManifestForPage(_Page.home), owner);
      expect(registry.findManifestForPage(_Page.detail), isNull);
    });

    test('findManifestForPage skips disabled SDKs', () {
      final disabled = _FakeSDK(
        enabled: false,
        pages: const {_Page.home: PageConfig(deeplinkPath: '/home')},
      );
      registry.register(disabled);

      expect(registry.findManifestForPage(_Page.home), isNull);
    });

    group('resolveInitialPath', () {
      test('returns fallback when no SDKs are registered', () {
        expect(registry.resolveInitialPath(), '/');
      });

      test('returns fallback when no SDK implements InitialPathProvider', () {
        registry.register(_FakeSDK());

        expect(registry.resolveInitialPath(fallback: '/splash'), '/splash');
      });

      test('resolves claims in priority order, lower wins', () {
        registry
          ..register(
            _ClaimingSDK(
              claim: const InitialPathClaim(priority: 100, resolve: _home),
            ),
          )
          ..register(
            _ClaimingSDK(
              claim: const InitialPathClaim(priority: 10, resolve: _intro),
            ),
          );

        expect(registry.resolveInitialPath(), '/introduction');
      });

      test('skips claims that resolve to null and tries the next', () {
        registry
          ..register(
            _ClaimingSDK(
              claim: InitialPathClaim(priority: 10, resolve: () => null),
            ),
          )
          ..register(
            _ClaimingSDK(
              claim: const InitialPathClaim(priority: 20, resolve: _auth),
            ),
          )
          // Non-provider SDKs simply take no part in resolution.
          ..register(_FakeSDK());

        expect(registry.resolveInitialPath(), '/auth');
      });

      test('returns fallback when every claim resolves to null', () {
        registry
          ..register(
            _ClaimingSDK(
              claim: InitialPathClaim(priority: 10, resolve: () => null),
            ),
          )
          ..register(
            _ClaimingSDK(
              claim: InitialPathClaim(priority: 20, resolve: () => null),
            ),
          );

        expect(registry.resolveInitialPath(), '/');
      });

      test('excludes claims from disabled SDKs', () {
        registry
          ..register(
            _ClaimingSDK(
              enabled: false,
              claim: const InitialPathClaim(priority: 10, resolve: _intro),
            ),
          )
          ..register(
            _ClaimingSDK(
              claim: const InitialPathClaim(priority: 100, resolve: _home),
            ),
          );

        expect(registry.resolveInitialPath(), '/home');
      });

      test('ties in priority resolve in registration order', () {
        registry
          ..register(
            _ClaimingSDK(
              claim: InitialPathClaim(priority: 10, resolve: () => '/first'),
            ),
          )
          ..register(
            _ClaimingSDK(
              claim: InitialPathClaim(priority: 10, resolve: () => '/second'),
            ),
          );

        expect(registry.resolveInitialPath(), '/first');
      });
    });
  });
}

String? _home() => '/home';
String? _intro() => '/introduction';
String? _auth() => '/auth';
