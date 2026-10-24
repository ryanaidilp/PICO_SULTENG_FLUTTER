import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:pengaturan/src/pengaturan_manifest.dart';
import 'package:pengaturan/src/pengaturan_sdk.dart';

/// What the Pengaturan feature puts in the app root.
///
/// - [PengaturanManifest] in [FeatureSDKRegistry], so
///   pre-launch registers the routes.
/// - [PengaturanSDK] as a lazy singleton, built on first
///   resolve.
///
/// A port this feature owns and other features use is registered here too,
/// once, with a `// di-global: <reason>` comment; this feature reads it back
/// through its imports file:
/// ```dart
/// // di-global: other features read it through the port.
/// gh.lazySingleton<PengaturanReader>(PengaturanReaderImpl.new);
/// ```
class PengaturanGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const PengaturanManifest());
    gh.lazySingleton<PengaturanSDK>(PengaturanSDKImpl.new);
  }
}
