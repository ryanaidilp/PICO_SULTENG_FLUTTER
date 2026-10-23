import 'package:feature_sdk/src/feature_manifest.dart';
import 'package:feature_sdk/src/feature_sdk.dart';
import 'package:identifiers/identifiers.dart';

/// Registry of feature manifests, read by the host during pre-launch.
///
/// Each feature registers its [FeatureManifest] from its global DI module.
/// The host reads this registry to build the route table without knowing
/// the features. Everything in it is built before the first frame, which is
/// why a feature registers its cheap manifest here and keeps its SDK a lazy
/// singleton:
///
/// ```dart
/// class HomeImplGlobalModule() extends MicroPackageModule {
///   @override
///   FutureOr<void> init(GetItHelper gh) {
///     FeatureSDKRegistry.instance.register(const HomeManifest());
///     GetIt.instance.registerLazySingleton<HomeSDK>(HomeSDKImpl.new);
///   }
/// }
/// ```
///
/// A [FeatureSDK] is also a manifest, so a feature that must exist at boot
/// (see [FeatureSDK]) registers itself here.
class FeatureSDKRegistry._() {
  /// The singleton instance of the registry.
  static final FeatureSDKRegistry instance = FeatureSDKRegistry._();

  final List<FeatureManifest> _manifests = [];

  /// All registered manifests, as an unmodifiable view.
  List<FeatureManifest> get manifests => List.unmodifiable(_manifests);

  /// Registered manifests whose `isEnabled` is true.
  ///
  /// Use this when iterating manifests to register routes, initialize, or
  /// dispatch. Disabled features are skipped so their code can be stripped
  /// from the binary.
  List<FeatureManifest> get enabledManifests =>
      List.unmodifiable(_manifests.where((m) => m.isEnabled));

  /// Combined page configurations from all enabled manifests.
  ///
  /// Each entry maps a [PageIdentifier] to its [PageConfig]. The host
  /// app uses this for deep-link routing, FCM-routed notification
  /// targets, auth gating, and analytics screen logging — none of which
  /// require importing the owning feature.
  Map<PageIdentifier, PageConfig> get enabledPageConfigurations {
    final combined = <PageIdentifier, PageConfig>{};
    for (final manifest in _manifests) {
      if (!manifest.isEnabled) continue;
      combined.addAll(manifest.pageConfigurations);
    }
    return Map.unmodifiable(combined);
  }

  /// Returns the enabled manifest that owns [identifier], or null if no
  /// enabled manifest declares it in its `pageConfigurations`.
  FeatureManifest? findManifestForPage(PageIdentifier identifier) {
    for (final manifest in _manifests) {
      if (!manifest.isEnabled) continue;
      if (manifest.pageConfigurations.containsKey(identifier)) return manifest;
    }
    return null;
  }

  /// Resolves the app's initial route from enabled manifests'
  /// [InitialPathClaim]s.
  ///
  /// Only manifests that opt in by implementing [InitialPathProvider] take part.
  /// Claims are sorted by ascending priority (lower wins) and resolved in
  /// order; the first non-null result wins. Claims that resolve to null are
  /// skipped. Ties in priority resolve in registration order. Returns
  /// [fallback] if no claim resolves.
  String resolveInitialPath({String fallback = '/'}) {
    final claims =
        enabledManifests
            .whereType<InitialPathProvider>()
            .map((provider) => provider.initialPathClaim)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    for (final claim in claims) {
      final path = claim.resolve();
      if (path != null) return path;
    }
    return fallback;
  }

  /// Marks the start of the host's pre-launch sweep.
  ///
  /// The host calls this right before it reads the registry to run
  /// `registerRoutes()` and `initialize()`. After it, [register] trips a
  /// debug assert: a manifest that joins later would silently miss the
  /// sweep.
  void seal() => _sealed = true;

  bool _sealed = false;

  /// Register a feature manifest for auto-discovery.
  ///
  /// Call it from the feature's global DI module. Throws a [StateError] if
  /// the manifest is already registered.
  void register(FeatureManifest manifest) {
    assert(
      !_sealed,
      'FeatureManifest ${manifest.runtimeType} registered after the '
      'pre-launch sweep started. Register it from the global DI module; a '
      'FeatureSDK that registers itself must be registered eagerly '
      '(registerSingleton), never lazily.',
    );
    if (_manifests.contains(manifest)) {
      throw StateError(
        'FeatureManifest ${manifest.runtimeType} is already registered.',
      );
    }
    _manifests.add(manifest);
  }

  /// Unregister a feature manifest.
  void unregister(FeatureManifest manifest) {
    _manifests.remove(manifest);
  }

  /// Clear all registered manifests.
  ///
  /// Useful for testing.
  void clear() {
    _manifests.clear();
    _sealed = false;
  }
}
