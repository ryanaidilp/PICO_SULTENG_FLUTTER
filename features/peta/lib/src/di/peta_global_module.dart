import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:peta/src/peta_manifest.dart';
import 'package:peta/src/peta_sdk.dart';

/// What the Peta feature puts in the app root.
///
/// - [PetaManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [PetaSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<PetaReader>(PetaReaderImpl.new);
/// ```
class PetaGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const PetaManifest());
    gh.lazySingleton<PetaSDK>(PetaSDKImpl.new);
  }
}
