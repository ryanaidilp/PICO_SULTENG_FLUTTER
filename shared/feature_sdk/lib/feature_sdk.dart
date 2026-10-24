/// Feature contracts: manifests, SDKs, the registry and per-feature
/// containers.
library;

// Re-export identifier types so any consumer of the contract can implement
// `pageConfigurations` without needing a separate dependency declaration.
export 'package:identifiers/identifiers.dart' show PageConfig, PageIdentifier;

export 'src/feature_container.dart';
export 'src/feature_manifest.dart';
export 'src/feature_sdk.dart';
export 'src/feature_sdk_registry.dart';
