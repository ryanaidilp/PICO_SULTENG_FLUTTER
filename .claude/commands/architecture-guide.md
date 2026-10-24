# Architecture Guide

Quick reference for the monorepo architecture patterns.

## Package Split Decision Tree

```
Does this package have multiple implementations?
  YES -> API/Impl split (e.g., network_sdk_api + network_sdk_dio + network_sdk_http)
  NO  -> Do other packages need its contract without the implementation?
    YES -> API/Impl split (e.g., auth_api consumed by home_impl)
    NO  -> Single package (default)
```

## Dependency Flow (strict -- only flows DOWN)

```
apps/pico
  |
features/ (impl packages)
  |
infrastructure/ (impl packages)
  |
packages/ (pico_ui_kit, pico_asset)
  |
shared/ (dependencies, dependencies_core, feature_sdk, router_registry, app_config, consent_api/impl, identifiers, locale_core)
```

**Rules:**
- Features never import another feature's `_impl`; they may import its `_api`
- `_api` packages are pure Dart and depend only on `shared/dependencies_core`
- `shared/` packages never depend on features or infrastructure
- `melos run graph:cycles` and `melos run graph:validate` check the graph

## DI Pattern Summary

| Type | Pattern | When |
|------|---------|------|
| Infrastructure | `@InjectableInit.microPackage()`, declared under `archipelago: di_modules:` and wired by `generate host-registry` | Pre-launch, blocking |
| Analytics/Feature Flags | Explicit `$initXxxDI(getIt)` | Post-launch, non-blocking |
| Feature manifest | `FeatureSDKRegistry.register(const XManifest())` in the global module | Read in pre-launch |
| Feature SDK | Lazy singleton in the global module (eager `FeatureSDK` only for boot-critical features) | Built on first resolve |
| Feature internals | `FeatureContainer` (child GetIt, explicit imports) | Built by the shell's first lease, torn down after the last release |

## Two-Phase Init

**Pre-launch (blocking):**
1. Global DI initialized
2. Feature manifests registered by global modules (SDKs stay lazy)
3. Routes registered from each manifest via FeatureSDKRegistry
4. RouteRegistry locked
5. AppRouter created

**Post-launch (non-blocking):**
1. Analytics initialized
2. Feature flags loaded
3. Background sync started

## Production-Flavor Stripping

```bash
melos run build-prepare:production  # Production flavor: debug tooling -> noop
melos run build-prepare:debug       # Swap back for development
```

Internal flavors (`internal_flavors` in `build_prepare.yaml`) keep the tooling even in release mode. The Fastfile passes the build's own flavor, so manual runs are rarely needed.
