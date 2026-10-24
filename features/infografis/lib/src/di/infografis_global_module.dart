import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:infografis/src/infografis_manifest.dart';
import 'package:infografis/src/infografis_sdk.dart';

/// What the Infografis feature puts in the app root.
///
/// - [InfografisManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [InfografisSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<InfografisReader>(InfografisReaderImpl.new);
/// ```
class InfografisGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const InfografisManifest());
    gh.lazySingleton<InfografisSDK>(InfografisSDKImpl.new);
  }
}
