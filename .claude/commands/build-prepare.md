# Build Prepare

Swap debug tooling for its noop twins by build flavor, and Marionette by build mode.

## Usage

**Before a build, pass the build's own flavor:**
```bash
dart run monorepo_toolkit build-prepare --flavor <flavor> --mode release
```
Flavors in `internal_flavors` (default `development`, `staging`, `alpha`, `beta`) keep the debug tooling, even in release mode, so QA and beta testers have the debugger and the Blackbox recorder. Every other flavor, including a new one, swaps debug-only dependencies (e.g. app_debugger) for their noop twins (e.g. app_debugger_noop). Monitoring and the app launch tracker are never swapped: they ship in every flavor, gated by consent.

`--mode release|profile` also swaps the `debug_build_only` list (Marionette: `app_marionette` -> `app_marionette_noop`) for every flavor; `--mode debug` restores it. Without `--mode` that list is left as it is.

**After the build, check for leaks:**
```bash
dart run monorepo_toolkit build-prepare --check-leaks --flavor <flavor> --mode release
```
Fails a production-flavor build when a mapped debug package or a `debug_only` package still resolves for the app, and any release or profile build that still resolves `app_marionette`, `marionette_flutter`, `marionette_mcp` or `marionette_logging`.

**Restore:**
```bash
dart run monorepo_toolkit build-prepare --restore
```

Melos shortcuts: `melos run build-prepare:production` (alias `build-prepare:release`) and `melos run build-prepare:debug`. Never run the production swap before an internal build. The Fastfile already runs all three steps.

## Configuration

Edit `build_prepare.yaml` at workspace root. A new project starts with empty `mappings` and `debug_only`; the debugger and Blackbox bricks add their entries inside the markers when you generate them. A full file looks like:
```yaml
build_prepare:
  internal_flavors: [development, staging, alpha, beta]
  mappings:
    - debug: app_debugger
      release: app_debugger_noop
  debug_only: [app_blackbox_metrics]   # no noop twin, must never resolve in production
  debug_build_only:                    # swapped by --mode, every flavor
    - debug: app_marionette
      release: app_marionette_noop
    - marionette_flutter               # no twin, must never resolve in release/profile
  target_paths:
    - apps/pico
```
