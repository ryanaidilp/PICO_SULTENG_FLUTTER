import 'dart:async';

import 'package:dependencies/di.dart' show GetIt, GetItHelper;
import 'package:dependencies/state.dart' show BlocBase;
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home/src/di/home_container.dart';
import 'package:home/src/di/home_global_module.dart';
import 'package:home/src/home_manifest.dart';
import 'package:home/src/home_sdk.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';

void main() {
  setUp(FeatureSDKRegistry.instance.clear);
  tearDown(FeatureSDKRegistry.instance.clear);

  test('the global module registers the manifest and a lazy SDK', () {
    final root = GetIt.asNewInstance();
    HomeGlobalModule().init(GetItHelper(root));

    expect(FeatureSDKRegistry.instance.manifests.single, isA<HomeManifest>());
    expect(root.checkLazySingletonInstanceExists<HomeSDK>(), isFalse);
    root<HomeSDK>();
    expect(root.checkLazySingletonInstanceExists<HomeSDK>(), isTrue);
  });

  test('the container resolves only what it registers or imports', () async {
    // A root with only the imports' types in it: add each type forwarded
    // in home_imports.dart. Duration stands in for a
    // root type the feature does not import.
    final root = GetIt.asNewInstance()..registerSingleton(Duration.zero);
    final container = FeatureContainer(
      'home',
      root: root,
      build: buildHomeContainer,
    );
    final lease = container.acquire();
    await lease.ready;

    expect(lease.get<Duration>, throwsStateError);

    await lease.release();
  });

  test(
    'the container builds from its imports and empties on release',
    () async {
      // A root with only the types home_imports.dart
      // forwards: register one fake per forwarded type.
      final root = GetIt.asNewInstance()
        ..registerSingleton<CaseRepository>(FakeCaseRepository())
        ..registerSingleton<ContentRepository>(FakeContentRepository());
      late GetIt child;
      final container = FeatureContainer(
        'home',
        root: root,
        build: (c, r) => buildHomeContainer(child = c, r),
      );
      final lease = container.acquire();
      await lease.ready;

      // Builds the singletons the container owns, then resolves every
      // registration (factories too), so a missing import throws here.
      final owned = child.findAll<Object>(instantiateLazySingletons: true);
      child.findAll<Object>(
        instantiateLazySingletons: true,
        callFactories: true,
      );

      await lease.release();

      expect(container.debugSnapshot().built, isFalse);
      expect(child.findAll<Object>(), isEmpty);
      // A closable singleton the container owns needs `dispose:`.
      expect(
        [
          for (final o in owned)
            if (_isClosed(o) == false) o.runtimeType,
        ],
        isEmpty,
        reason: 'Register these with `dispose:` so the teardown closes them.',
      );
    },
  );
}

/// Whether a closable instance is closed; null for anything else.
bool? _isClosed(Object o) => switch (o) {
  BlocBase(:final isClosed) => isClosed,
  StreamController(:final isClosed) => isClosed,
  _ => null,
};
