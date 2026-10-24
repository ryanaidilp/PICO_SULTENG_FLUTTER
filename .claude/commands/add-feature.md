# Add Feature Module

Generate a new feature module for the Pico monorepo.

## Input

Feature name: $ARGUMENTS (e.g., "profile", "settings", "onboarding")

## Preferred: Archipelago CLI

```bash
archipelago generate feature_monorepo_skeleton
```

It generates the feature with its manifest, lazy SDK, `FeatureContainer`, shell page, `di_modules` declaration and DI test, registers the module in the app injector, and keeps a generation record in `.archipelago/generated/feature_monorepo_skeleton/<feature>.json` (see the `archipelago-upgrade` skill).

## Native Code

For Android and iOS code in the feature, set `isPlugin: true` in `archipelago generate feature_monorepo_skeleton`. It adds `android/`, `ios/` and a Dart `MethodChannel` wrapper in `lib/src/platform/` to the feature package (`_impl` in an API/Impl split; `_api` stays pure Dart). Add a native call as a `case` in the Kotlin `when` and the Swift `switch`, plus a method on the wrapper.

## Determine Package Strategy

**Single package** (default -- when no other feature depends on this one):
- Create at `features/$ARGUMENTS/`

**API/Impl split** (when other features consume this feature's contracts):
- Create at `features/$ARGUMENTS/${ARGUMENTS}_api/` + `features/$ARGUMENTS/${ARGUMENTS}_impl/`
- Other features depend on `_api` only, never `_impl` (`test/architecture/feature_boundary_test.dart` enforces it)

## Manual Steps

1. Create the package (the workspace globs `features/**`, so no root `pubspec.yaml` edit is needed):
   - `pubspec.yaml` -- depends on `shared/dependencies`, `shared/feature_sdk`, `shared/router_registry`, the UI kit
   - `lib/src/<name>_manifest.dart` -- a const `XManifest extends FeatureManifest` with `registerRoutes(RouteRegistry)`; it never resolves from GetIt
   - The SDK port (`XSDK`, a plain interface with `launch()`) and `XSDKImpl` with a plain constructor
   - `lib/src/di/<name>_global_module.dart` -- `FeatureSDKRegistry.instance.register(const XManifest())` and `gh.lazySingleton<XSDK>(XSDKImpl.new)`
   - With local deps: `lib/src/di/<name>_imports.dart` + `<name>_container.dart`, and a shell page holding a `FeatureLease`
   - `lib/src/presentation/` -- pages and state holders (created in the shell from `_lease.get<T>()`)
2. Declare the module in the feature's own `pubspec.yaml`:
   ```yaml
   archipelago:
     di_modules:
       - class: XGlobalModule
         depends_on: []   # packages whose GetIt types init() reads eagerly
   ```
3. Add the feature to `apps/pico/pubspec.yaml`, then `dart run monorepo_toolkit generate host-registry` (rewrites the injector's marker regions).
4. `dart pub get && melos run build && melos run di:check && melos run analyze`

The `feature-di-registration` skill has the full rules (eager exceptions, test prerequisites, guard tests).

## Architecture Rules

- The SDK is lazy: built on first resolve. Only a feature that must exist before the first frame is an eager `FeatureSDK` (listed in `lazy_feature_sdk_test.dart`'s `_eagerByDesign`)
- Local dependencies live in the feature's `FeatureContainer`, built by the shell's first lease and torn down after the last release
- Cross-feature communication: via ports and events in `_api`, never direct `_impl` imports
