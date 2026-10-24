import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:vaksin/src/vaksin_manifest.dart';
import 'package:vaksin/src/vaksin_sdk.dart';

/// What the Vaksin feature puts in the app root.
///
/// - [VaksinManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [VaksinSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<VaksinReader>(VaksinReaderImpl.new);
/// ```
class VaksinGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const VaksinManifest());
    gh.lazySingleton<VaksinSDK>(VaksinSDKImpl.new);
  }
}
