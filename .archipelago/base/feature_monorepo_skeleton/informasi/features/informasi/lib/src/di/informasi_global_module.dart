import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:informasi/src/informasi_manifest.dart';
import 'package:informasi/src/informasi_sdk.dart';

/// What the Informasi feature puts in the app root.
///
/// - [InformasiManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [InformasiSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<InformasiReader>(InformasiReaderImpl.new);
/// ```
class InformasiGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const InformasiManifest());
    gh.lazySingleton<InformasiSDK>(InformasiSDKImpl.new);
  }
}
