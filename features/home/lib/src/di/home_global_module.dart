import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:home/src/home_manifest.dart';
import 'package:home/src/home_sdk.dart';

/// What the Home feature puts in the app root.
///
/// - [HomeManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [HomeSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<HomeReader>(HomeReaderImpl.new);
/// ```
class HomeGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const HomeManifest());
    gh.lazySingleton<HomeSDK>(HomeSDKImpl.new);
  }
}
