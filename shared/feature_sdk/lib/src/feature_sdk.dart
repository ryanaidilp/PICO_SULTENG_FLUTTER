import 'package:feature_sdk/src/feature_manifest.dart';
import 'package:flutter/widgets.dart';

/// A [FeatureManifest] that is also the feature's own entry point.
///
/// Registering one in `FeatureSDKRegistry` means the SDK object itself is
/// built before the first frame. Use it only for features that must exist
/// at boot anyway:
///
/// - features whose [initialize] does real pre-first-frame work (auth's
///   session restore, a startup update check),
/// - debug tooling and passive service SDKs that wire themselves up at
///   startup.
///
/// Every other feature registers a const [FeatureManifest] and a lazy SDK
/// behind its `_api` port (see [FeatureManifest]). The port is a plain
/// interface with `launch()` and its destinations; it does not extend this
/// class.
///
/// ```dart
/// // AuthSDK (auth_api) implements FeatureSDK; the global module registers
/// // the result eagerly with registerSingleton.
/// class AuthSDKImpl implements AuthSDK {
///   AuthSDKImpl._();
///
///   static AuthSDKImpl create() {
///     final sdk = AuthSDKImpl._();
///     FeatureSDKRegistry.instance.register(sdk);
///     return sdk;
///   }
///   // ...
/// }
/// ```
abstract class const FeatureSDK() extends FeatureManifest {
  /// Launch the feature's main flow.
  ///
  /// The single public entry point for navigating into this feature.
  Future<void> launch(BuildContext context);
}
