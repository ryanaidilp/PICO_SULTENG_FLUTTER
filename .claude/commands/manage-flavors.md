# Manage Flavors

Manage app flavors (development, staging, production) for `apps/pico`.

## Commands

```bash
melos run flavor:list-apps                                         # apps that support flavors
melos run flavor:list -- --app pico               # flavors of one app
melos run flavor:add -- --app pico --name qa      # add a flavor
melos run flavor:generate -- --app pico           # run flutter_flavorizr for the app
melos run flavor:sync                                              # central flavors.yaml -> every app
```

`--app` is required on `list`, `add` and `generate`. `flavor:sync` takes optional `--app`, `--init` (build `flavors.yaml` from the apps) and `--from-apps`.

`flavor add` and `flavor generate` run `dart run flutter_flavorizr --force` and retry it up to 3 times, 3 s apart: flutter_flavorizr's first step downloads an archive from GitHub without checking the response, so a network hiccup fails it. If all attempts fail, the last lines of its output are printed; fix the network and rerun.

## After adding a flavor

1. `melos run env:sync` -- merges the new flavor into the `.env.<flavor>` files and the `FlavorStatus` enum (it never overwrites real values), then fill in `shared/app_config/.env.<flavor>`.
2. Add an entry point `apps/pico/lib/main_<flavor>.dart` (production uses `main.dart`), copied from `main_development.dart`, with the same `archipelago:imports` markers.
3. Add the flavor to `internal_flavors` in `build_prepare.yaml` if QA builds of it should keep the debug tooling.

## Run a flavor

`dart run monorepo_toolkit prepare --flavor <flavor>` switches `.env`, regenerates envied code and runs build-prepare in one idempotent step. The IDE configs call it for you:

- VS Code: `.vscode/launch.json` has `<App> - <Flavor>` entries (plus Profile and Release variants), each with a `prepare-<flavor>` pre-launch task from `.vscode/tasks.json`.
- JetBrains: `.run/pico_<flavor>[_profile|_release].run.xml` and `.run/prepare-<flavor>.run.xml`.

`flavor add` and `flavor generate` write the entries for a new flavor and keep existing ones. Both folders are committed; `.idea/` is not.

## Configuration

- Central: `flavors.yaml` at workspace root
- Per app: `apps/pico/flavorizr.yaml`
- Launcher icons: `apps/pico/flutter_launcher_icons-<flavor>.yaml`
- Env: `shared/app_config/.env.<flavor>` (gitignored; `.env.example` is committed)
