// Guards ADR-038: a feature's SDK is built on first use, not at boot.
//
// The regression is silent. Swapping a feature's `lazySingleton` for
// `singleton`, or turning its port back into a `FeatureSDK`, puts the
// feature on the boot path with no visible symptom. Nothing here lists
// features: the manifests come from `FeatureSDKRegistry`, and the built
// instances from `findAll`, the only GetIt call that tells "registered"
// from "built" without building anything.
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico/di/injector.dart';

import '../support/composition_root_harness.dart';

/// `FeatureSDK`s that are built at boot on purpose, by implementation class
/// name. Each must do work before the first frame (ADR-038). Add a name
/// only with that reason; a feature that can wait gets a `FeatureManifest`
/// and a lazy port instead. Names of packages this app does not use are
/// harmless.
const _eagerByDesign = {
  // Restores the session; the network layer's AuthTokenProvider reads it.
  'AuthSDKImpl',
  // Its provider handlers attach the FCM/OneSignal listeners at boot.
  'PushNotificationSDKImpl',
  // Start their monitoring, update check or registry in initialize().
  'ConnectivitySDKImpl',
  'ShorebirdUpdaterSDKImpl',
  'WebViewAdvancedSDKImpl',
  'HomeWidgetSDKImpl',
  'SessionRecorderSDKImpl',
  // Debug tooling: wires its interceptors and panels at startup.
  'AppDebuggerSDKImpl',
  'AnalyticsInspectorSDKImpl',
  'BridgeInspectorSDKImpl',
  'FeatureFlagSpooferSDKImpl',
  'NetworkInspectorSDKImpl',
  'StorageInspectorSDKImpl',
  'WebSocketInspectorSDKImpl',
};

String _name(Object o) => o.runtimeType.toString();

void main() {
  setUpAll(() async {
    await installCompositionRootPrerequisites();
    await initializeInjector();
  });

  tearDownAll(() async {
    await getIt.reset();
    FeatureSDKRegistry.instance.clear();
  });

  test('only allowlisted features register an eager FeatureSDK', () {
    final eager = [
      for (final manifest in FeatureSDKRegistry.instance.enabledManifests)
        if (manifest is FeatureSDK && !_eagerByDesign.contains(_name(manifest)))
          _name(manifest),
    ];

    expect(
      eager,
      isEmpty,
      reason:
          'Register a const FeatureManifest and the SDK as a lazy singleton '
          '(ADR-038), or add it to _eagerByDesign with the reason it must '
          'exist before the first frame.',
    );
  });

  test('no lazy feature SDK is built by initializeInjector()', () {
    final built = [
      for (final instance in getIt.findAll<Object>())
        if (_name(instance).endsWith('SDKImpl') &&
            !(instance is FeatureSDK &&
                _eagerByDesign.contains(_name(instance))))
          _name(instance),
    ];

    expect(
      built,
      isEmpty,
      reason:
          'These SDKs were built at boot. Register them with '
          'lazySingleton, and make sure no module or initializer resolves '
          'them during initializeInjector().',
    );
  });
}
