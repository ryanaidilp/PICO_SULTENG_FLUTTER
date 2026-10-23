---
name: generator-markers
description: Use when editing bootstrap.dart, initializer files, build_prepare.yaml, or any file containing "archipelago:" comment markers.
---

# Generator Markers

## Overview

Some hand-written files contain paired comment anchors that the Archipelago generator and brick post-gen hooks use to insert or strip code:

```dart
// archipelago:analytics_initializer:start
...generated/managed code...
// archipelago:analytics_initializer:end
```

Known marker sections:

| File | Markers |
|---|---|
| `apps/pico/lib/bootstrap.dart` | `app_debugger:pre_init` (generated projects), `firebase:init`, `app_debugger:pre_run` |
| `features/app_debugger/app_debugger/lib/src/di/debug_tools.dart` (`DebugTools.wire()`) | `debug_panel_pages` (each `app_debugger_*` panel brick and the Blackbox recorder add their tool page), `feature_flag_spoofer_delegate`, `analytics_inspector_interceptor` |
| `apps/pico/lib/app.dart` | `app_builder` (inside `MaterialApp.router`: app_debugger fills it with the debug overlay `builder:`, and any other `builder:` wrapper must compose inside this one region); `navigator_observers` (inside the `navigatorObservers: () => [...]` builder passed to `router.config`: each entry is a new `NavigatorObserver`, e.g. `journey_tracker`'s `JourneyNavigatorObserver`) |
| `apps/pico/lib/host/initializers/pre_launch_initializer.dart` | `pre_launch_imports`, `pre_launch_initializers` |
| `apps/pico/lib/host/initializers/post_launch_initializer.dart` | `post_launch_imports`, `analytics_initializer`, `feature_flag_initializer`, `deeplink_initializer`, `post_launch_initializers` |
| `apps/pico/lib/main.dart`, `main_development.dart`, `main_staging.dart` | `imports` (all three flavor entrypoints carry the same marker set) |
| `apps/pico/lib/di/injector.dart` | `feature_imports`, `feature_modules_before`, `feature_modules_after` (generated, see below) |
| `build_prepare.yaml` | `build_prepare:mappings` |

`pre_launch_initializers` is the pre-launch counterpart to post-launch's three initializer markers: it sits inside the list literal passed to `PreLaunchInitializer._([...])` in `PreLaunchInitializer.create()`, so an entry injected between its `:start`/`:end` lines is a plain list element (must end with a trailing comma). Bricks that need a blocking pre-launch step inject here; the consumers are `app_blackbox_recorder`, which adds `LaunchTraceSourceInitializer` when the launch tracker is installed, `app_debugger`, which adds `LaunchTraceFeedInitializer` under the same condition, and `background_sdk`, which adds `BackgroundWorkInitializer`. `pre_launch_imports` sits in the file's import block for the corresponding `import` statement. This region is brick-owned; app-owned pre-launch steps go through `PreLaunchInitializer.create(additional: [...])`/`PreLaunchInitializerController.create(additional: [...])` instead — see the doc comment on `PreLaunchInitializer` for exactly how the two combine (brick-owned first, then `additional`, concatenated before the sequential/parallel split runs).

The last three are **generated**, not hand-maintained: `monorepo_toolkit generate host-registry` scans every workspace package's `pubspec.yaml` for an `archipelago: di_modules: [...]` declaration (class name, optional `import:` override, optional `depends_on:` package list, optional `scope: before|after`), resolves a deterministic registration order (explicit `depends_on` edges, then each package's own declaration order, then alphabetical), and rewrites all three regions from scratch. Never hand-edit content inside `feature_imports`/`feature_modules_before`/`feature_modules_after` — declare the owning package's manifest entry in its own `pubspec.yaml` instead and re-run the generator. `feature_modules_after` corresponds to `externalPackageModulesAfter` and is currently always empty in `pico` (no package declares `scope: after` yet) but the marker pair must still exist, because `HostRegistryService` unconditionally regenerates all three regions and throws if any is missing.

Brick hooks insert their own module into the `feature_imports`/`feature_modules_before` regions when you generate them; running `generate host-registry` afterwards normalises the order.

The test harness has its own generated pair: `test_prerequisite_imports` and `test_prerequisites` in `apps/pico/test/support/composition_root_harness.dart`. `dart run monorepo_toolkit generate test-harness` scans every workspace package's `pubspec.yaml` for an `archipelago: test_prerequisites: [...]` declaration (class name, `reason`, optional `import:` override, optional `depends_on:`) and rewrites both regions. Each entry becomes an import of `package:<pkg>/testing.dart` and an `await <Class>().install();` line with the reason as its doc comment. `apps/pico/test/di/injector_test.dart` calls `installCompositionRootPrerequisites()` before `initializeInjector()`. Never hand-edit inside these regions and never add a fake to the test file: declare the prerequisite in the package that does the platform I/O. An empty region is normal: it means no installed package touches a platform during DI init. `generate test-harness --check` fails when the file is out of date.

## Rules

1. **Never delete, rename, or reorder a marker comment.** The generator matches them textually; an unbalanced or missing pair makes future brick installs fail or inject code in the wrong place.
2. Treat the content **between** a start/end pair as machine-managed: edit it only when the task is explicitly about that section, and keep the markers hugging the block.
3. New hand-written code goes **outside** marker pairs.
4. When adding a swappable debug/release package mapping, add it **inside** `# archipelago:build_prepare:mappings:start/end` in `build_prepare.yaml` — mappings outside the pair are ignored by the mapping updater.
5. A formatter will not break markers (they're line comments), but refactoring tools that move/rewrap code can — re-check marker pairs after large automated edits to these files.
6. To register a new DI module in `injector.dart`, declare it in the owning package's own `pubspec.yaml` (`archipelago: di_modules:`) and run `dart run monorepo_toolkit generate host-registry` — do not hand-edit `feature_imports`/`feature_modules_before`/`feature_modules_after` directly except as a one-off unblock, and re-run the generator afterward to normalize it back to canonical form.
7. Adding a marker to one flavor entrypoint (`main.dart`) but not its siblings (`main_development.dart`, `main_staging.dart`) breaks the next brick that injects there — treat the three files as one unit.
8. To make `initializeInjector()` pass under `flutter test` when a package's DI init touches a platform channel, declare a test prerequisite in that package's `pubspec.yaml` (`archipelago: test_prerequisites:`) and run `dart run monorepo_toolkit generate test-harness`. Do not hand-edit `test_prerequisite_imports`/`test_prerequisites`.

## Red flags

- "These comments look like noise, I'll clean them up" — they are load-bearing anchors.
- A diff that shows a `:start` without its `:end` (or vice versa).
- Moving initialization code out of a marked section "for readability".

If a marker pair must move (e.g. file restructure), move the pair and its contents atomically and verify both lines survive.
