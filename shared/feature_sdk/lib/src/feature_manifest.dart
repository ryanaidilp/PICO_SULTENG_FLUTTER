import 'package:identifiers/identifiers.dart';
import 'package:router_registry/router_registry.dart';

/// A feature's claim on the app's initial route.
///
/// Registered manifests that want a say in where the app launches expose
/// this by implementing [InitialPathProvider].
/// `FeatureSDKRegistry.resolveInitialPath` sorts claims by [priority] and
/// resolves them in order, taking the first non-null result.
class const InitialPathClaim({
  /// Lower value wins. Convention: onboarding 10, auth 20, default home 100.
  required final int priority,

  /// Returns the path to launch at, or null to pass to the next claim
  /// (e.g. introduction returns null once completed).
  ///
  /// Runs when the router is built, after every manifest's
  /// `initialize()`, so it may read a lazy SDK.
  required final String? Function() resolve,
});

/// Opt-in interface for manifests that claim the app's initial route.
///
/// Implemented alongside [FeatureManifest]. It is not part of the base
/// contract, so manifests with no opinion on the startup route need no
/// changes:
///
/// ```dart
/// class const HomeManifest() extends FeatureManifest
///     implements InitialPathProvider {
///   @override
///   InitialPathClaim get initialPathClaim =>
///       InitialPathClaim(priority: 100, resolve: () => '/home');
/// }
/// ```
abstract interface class InitialPathProvider() {
  /// This manifest's claim on the app's initial route.
  InitialPathClaim get initialPathClaim;
}

/// What a feature contributes to the host before the first frame: its
/// routes, its page identifiers and its enable flag.
///
/// The host reads every registered manifest during pre-launch to build the
/// router, so a manifest is built at boot and must stay cheap. The feature's
/// behaviour (navigation, state, capabilities) lives in its SDK, a lazy
/// singleton behind the feature's `_api` port, built on first use:
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
/// A manifest must not resolve from the service locator in its constructor,
/// [isEnabled] or [registerRoutes]: that pulls the feature's graph onto the
/// boot path. Where a route needs a collaborator (a guard, say), pass a
/// provider closure so the lookup runs on navigation. [initialize] and
/// [dispose] may resolve freely.
abstract class const FeatureManifest() {
  /// Whether this feature is enabled in the current build.
  ///
  /// When `false`, the host app skips [registerRoutes], [initialize], and
  /// the feature's [pageConfigurations] are not aggregated. Combined with
  /// `build_prepare` per-flavor dependency swapping, this lets a flavor
  /// exclude entire features at compile time so their assets and code are
  /// stripped from the binary.
  bool get isEnabled => true;

  /// The page identifiers this feature owns, mapped to their config.
  ///
  /// Features contribute this so the host app can resolve cross-feature
  /// deep links, FCM-routed notifications, and analytics screen names
  /// without importing feature internals. Aggregated by
  /// `FeatureSDKRegistry.enabledPageConfigurations`.
  Map<PageIdentifier, PageConfig> get pageConfigurations => const {};

  /// Register feature routes to the registry.
  ///
  /// Called during pre-launch initialization, before the app router is
  /// created. Route objects are inert until navigated to, so declaring the
  /// whole table here costs only the descriptors.
  void registerRoutes(RouteRegistry registry);

  /// Pre-first-frame work, run after every manifest's [registerRoutes].
  ///
  /// Most features have none; the default does nothing, which keeps them
  /// off the boot path.
  Future<void> initialize() async {}

  /// Releases what [initialize] acquired. Called on app shutdown.
  Future<void> dispose() async {}
}
