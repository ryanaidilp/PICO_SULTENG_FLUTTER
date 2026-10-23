---
name: feature-di-registration
description: Use when creating or wiring a feature SDK, adding DI registration, or debugging features whose routes or SDK never appear at runtime.
---

# Feature DI Registration

## Overview

A feature contributes two objects:

- a **`FeatureManifest`**: routes, page configs, enable flag, optional initial-path claim. Registered in `FeatureSDKRegistry` from the global module. The registry is read **once**, during pre-launch, before the router is built.
- an **SDK** behind the feature's `_api` port: navigation and behaviour. A **lazy** singleton, built on first resolve.

## The pattern (copy from the home feature)

```dart
// 1. Manifest: const, dependency-free
class const HomeManifest() extends FeatureManifest
    implements InitialPathProvider {
  @override
  InitialPathClaim get initialPathClaim =>
      InitialPathClaim(priority: 100, resolve: () => '/home');

  @override
  void registerRoutes(RouteRegistry registry) => registry.register([...]);
}

// 2. Port (_api): plain interface, no FeatureSDK
abstract interface class HomeSDK() {
  Future<void> launch(BuildContext context);
  Future<void> goToSection(BuildContext context, String sectionId);
}

// 3. Global module: manifest + LAZY SDK
class HomeImplGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    FeatureSDKRegistry.instance.register(const HomeManifest());
    gh.lazySingleton<HomeSDK>(HomeSDKImpl.new);
  }
}
```

**The manifest rule:** a manifest never resolves from GetIt in its constructor, `isEnabled` or `registerRoutes`; that puts the feature's graph on the boot path. A route collaborator (a guard) comes through a provider closure. `initialize()`, `dispose()` and a claim's `resolve` may resolve; introduction's claim gets `isCompleted` as a closure from its global module. The `app_lints` rule `no_service_locator_in_manifest` enforces it.

**Returning a result:** a port method that hands data back returns `Future<T?>` (like auto_route's `push<T>()`); `null` means cancelled or dismissed.

**Eager exception:** a feature that must exist before the first frame (auth restores the session; debug tooling and passive service SDKs wire themselves up) implements `FeatureSDK` (a manifest plus `launch()`), registers itself from a static `create()` and is registered eagerly with `registerSingleton`. Never register such an SDK lazily: it would join the registry after the sweep, and the sealed registry trips a debug assert. Say why in the global module. A passive SDK with no routes and no startup work (autoscroll, feedback, ...) is not a `FeatureSDK`: register its port lazily and keep it out of the registry.

**Guard tests:** `apps/pico/test/di/lazy_feature_sdk_test.dart` fails when `initializeInjector()` builds a `*SDKImpl` that is not in its commented `_eagerByDesign` allowlist, or a manifest is an unlisted `FeatureSDK`. `base_scope_budget_test.dart` snapshots the instances built at boot (`flutter test --update-goldens` accepts a change), `port_singleton_test.dart` checks that `// di-global:` ports are singletons and that `*_imports.dart` files only forward, and `test/architecture/feature_boundary_test.dart` forbids depending on another feature's `_impl`. Each feature's `test/di/<name>_di_test.dart` builds its container from a fake root holding only the imported types and checks the teardown.

**Lint guard:** the `feature_global_module_allowlist` rule (`utilities/app_lints`) flags every other registration in a feature global module's `init`. It allows a `FeatureManifest`, the feature's own eager `FeatureSDK`, and the feature's own lazy port (a type in the same feature folder whose name ends in `SDK`). For a port that code outside the feature resolves from the root, put `// di-global: <reason>` on the same line or on its own comment line directly above, as `auth_impl`'s `AuthImplGlobalModule` does. The `no_service_locator_outside_di` rule flags `GetIt` reads in feature code outside `lib/src/di/`.

## Local (per-feature) DI: `FeatureContainer`

Global GetIt holds manifests, SDKs, infrastructure and ports. A feature's repos, datasources and use cases live in its own **container**, a child `GetIt` that never falls back to the root. Copy `features/home/home_impl/lib/src/di/` (or generate with `feature_monorepo_skeleton`):

```dart
// <name>_imports.dart: the only file that reads the root
void importHomeGlobals(GetIt child, GetIt root) {
  child.registerFactory<NetworkClient>(() => root<NetworkClient>()); // root keeps ownership
}

// <name>_container.dart
final homeContainer = FeatureContainer('home', root: GetIt.instance, build: buildHomeContainer);

void buildHomeContainer(GetIt child, GetIt root) {
  importHomeGlobals(child, root);
  initHomeLocalDI(child); // injectable-generated, runs against the child
}

// shell page
late final FeatureLease _lease;

@override
void initState() {
  super.initState();
  _lease = homeContainer.acquire();
  unawaited(_lease.ready.then((_) => _syncLocale()).catchError(_reportContainerError));
}

@override
void dispose() {
  unawaited(_lease.release().catchError(_reportContainerError));
  super.dispose();
}
```

- **Imports are explicit.** A root type the feature uses needs one `registerFactory` line in the imports file. A type that is neither registered nor imported throws `StateError`, so a missing import fails at once. A constructor parameter of an imported type goes in the injector's `ignoreUnregisteredTypes`.
- **Leases are ref-counted.** The first `acquire()` builds the child, the last `release()` awaits `reset(dispose: true)`. A same-route replace keeps the child; an `acquire()` during a teardown waits, then builds fresh. Release every lease, even one whose `ready` failed.
- **State holders live in the shell, not GetIt.** Create the Cubit/Bloc/ChangeNotifier in the shell (`BlocProvider`/`ChangeNotifierProvider`, or a `ProviderScope` for Riverpod) above the nested `AutoRouter`, passing `_lease.get<T>()` results to its constructor. Pages never read `GetIt`.
- **Ports a feature owns** are registered once, in its global module, with `// di-global: <reason>`; the feature imports them back. Two features importing one port get the same root instance.
- Any singleton registered by hand in the container that holds resources needs `dispose:`.
- Never call `GetIt.asNewInstance()` directly; use `FeatureContainer` so the imports and lifecycle come with it.
- Every feature uses a container; no feature pushes a named scope. auth keeps `AuthSDK` and `LoginRepository` eager in the root (session restore, token refresh) and forwards them into `authContainer`; paywall's `PaywallSDK` is a lazy root singleton forwarded into `paywallContainer` and handed to pages through `PaywallScope`.

## Wiring into the app

Declare the global module in the feature package's own `pubspec.yaml` under `archipelago: di_modules:` (class name, and `depends_on: [<package>]` for every package whose GetIt type your module's `init()` eagerly reads via `gh<T>()`/`GetIt.instance<T>()`/`getIt.getAll<T>()`), then run `dart run monorepo_toolkit generate host-registry` (from the workspace root) — it resolves the dependency graph and regenerates the `archipelago:feature_imports`/`archipelago:feature_modules_before` marker regions of `lib/di/injector.dart` for you. **Order matters** (that's exactly what `depends_on` encodes): infrastructure modules before feature modules that read them; provider modules (push, AI, social auth vendors) before the orchestrator that calls `getAll<T>()` on them. Do not hand-position entries in `injector.dart` — a package with no real ordering constraint gets an empty `depends_on: []` and the resolver's alphabetical tiebreak places it; see the `pubspec.yaml` of `auth_impl`, and of `social_auth_impl`, `push_notification_impl` or `ai_chat_impl` when installed, for real examples, including the two-declaration case (`ai_chat_impl` has both a config module and an orchestrator module, ordered by declaration order in its own `di_modules` list, not by `depends_on` on itself).

## Test prerequisites

`apps/pico/test/di/injector_test.dart` runs the real `initializeInjector()` under `flutter test`. Platform channels do not exist there, so a package whose DI init does platform I/O makes it fail with `MissingPluginException(No implementation found for method ...)`. Platform I/O during DI init means one of these:

- a `@preResolve` that calls a plugin (`package_info_provider`'s `PackageInfo.fromPlatform()`),
- a global module `init()` that eagerly resolves a plugin-backed type with `gh<T>()`,
- an eagerly built object whose constructor touches a plugin (`app_debugger_network`'s Alice).

Prefer moving the I/O to a pre-launch initializer. When it must stay, the package that does the I/O declares it:

1. Add `lib/src/testing/<package>_test_prerequisite.dart` with `<Name>TestPrerequisite() implements TestPrerequisite` (from `test_prereq`). `install()` sets the plugin's platform fake or mock values, is idempotent, and does not import `flutter_test`.
2. Export it from `lib/testing.dart`, and add `test_prereq` to the package's dependencies.
3. Declare it in the package's `pubspec.yaml`:

   ```yaml
   archipelago:
     test_prerequisites:
       - class: <Name>TestPrerequisite
         reason: >-
           What runs during $initGetIt and which plugin call it makes.
   ```

4. Run `dart run monorepo_toolkit generate test-harness`. It rewrites the marker regions of `apps/pico/test/support/composition_root_harness.dart`.

Never add a fake to `injector_test.dart`. If the package has a `_noop` twin, give the twin a matching `testing.dart` so the build_prepare swap still compiles the harness. Copy `infrastructure/package_info_provider` for the smallest example. `melos run di:check` fails when the harness is out of date.

## Checklist for a new feature

1. A const `XManifest extends FeatureManifest` with `registerRoutes`, and an `_api` port that does not extend `FeatureSDK`.
2. Global module registering `const XManifest()` and `gh.lazySingleton<XSDK>(XSDKImpl.new)`. Eager `FeatureSDK` only for a feature that must exist at boot.
3. With local deps: `<name>_imports.dart` + `<name>_container.dart`, and a shell page that holds a `FeatureLease`.
4. `registerRoutes(RouteRegistry)` on the manifest — pre-launch calls it before locking the registry.
5. `archipelago: di_modules:` declared in the feature's own `pubspec.yaml`, then `dart run monorepo_toolkit generate host-registry` run to regenerate the app injector's marker regions (falls back to hand-editing only those marker regions if the generator isn't available — never edit `externalPackageModulesBefore` outside them).
6. If the module's DI init touches a platform channel, a `test_prerequisites` entry and a `TestPrerequisite` in the same package (see "Test prerequisites" above), then `dart run monorepo_toolkit generate test-harness`.
7. Run codegen (`melos run build`) — never hand-edit `*.module.dart` / `*.config.dart`.
8. `melos run di:check`: fails when the injector regions or the test harness are out of date with the `pubspec.yaml` declarations.

## Symptoms → cause

| Symptom | Cause |
|---|---|
| Feature routes 404 / missing from router | Manifest not registered (or registered after the sweep), or module missing from app injector: declare it under `di_modules` and re-run `generate host-registry` |
| A `FeatureSDK`'s routes appear only after visiting another page | The eager exception registered lazily: register it with `registerSingleton` |
| A feature is built at boot although never opened | Its manifest resolves the SDK in `registerRoutes`/`isEnabled`, or the SDK is still an eager `FeatureSDK` |
| `GetIt: Object/factory not registered` from a lease | The root type is not forwarded in `<name>_imports.dart`, or the lease was used before `ready` / after `release()` |
| `MissingPluginException` from `injector_test.dart` | A package does platform I/O during DI init without a `test_prerequisites` declaration |
| Works in debug, gone in release | Package swapped to `_noop` by build_prepare — check `build_prepare.yaml` mappings |
