# Add Infrastructure Package

Add a new infrastructure SDK. If a ready-made brick fits (`archipelago brick list`), run `archipelago generate <brick>` instead.

## Input

Infrastructure name: $ARGUMENTS (e.g., "push_notification", "storage", "deep_link")

## Package Strategy

**Single package** (default): `infrastructure/$ARGUMENTS/`.

**API/Impl split**, only when there are several implementations, other packages need the contract without the implementation, or a `_noop` twin is needed for production builds.

## Steps (API/Impl split)

1. Create `infrastructure/${ARGUMENTS}_api/` with:
   - `pubspec.yaml` -- depends on `shared/dependencies_core` only (pure Dart, no Flutter, no vendor SDK)
   - `lib/${ARGUMENTS}_api.dart` -- barrel file
   - `lib/src/${ARGUMENTS}.dart` -- abstract contract

2. Create `infrastructure/${ARGUMENTS}_impl/` with:
   - `pubspec.yaml` -- depends on `_api` + `shared/dependencies` + the vendor SDK
   - `lib/${ARGUMENTS}_impl.dart` -- barrel exporting the `PackageModule`
   - `lib/src/di/injector.dart` -- `@InjectableInit.microPackage()`
   - `lib/src/${ARGUMENTS}_impl.dart` -- concrete implementation

3. Declare the module in the `_impl` package's `pubspec.yaml` (`archipelago: di_modules: [{class: <Name>ImplPackageModule, depends_on: []}]`), add `_impl` to `apps/pico/pubspec.yaml`, and run `dart run monorepo_toolkit generate host-registry`. The workspace globs `infrastructure/**`, so no root `pubspec.yaml` edit is needed.
4. If its DI init touches a platform channel (a `@preResolve` that calls a plugin), declare a test prerequisite and run `dart run monorepo_toolkit generate test-harness` (see the `feature-di-registration` skill).
5. A `_noop` twin keeps the impl's class names exactly; add the pair inside the `archipelago:build_prepare:mappings` markers of `build_prepare.yaml`.
6. `dart pub get && melos run build && melos run di:check && melos run analyze`

Import equatable, injectable, get_it and meta through the dependency barrels, never directly.
