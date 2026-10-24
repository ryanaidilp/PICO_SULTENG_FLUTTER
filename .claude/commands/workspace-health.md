# Workspace Health Check

Run a full health check on the monorepo.

## Steps

1. `dart pub get` -- resolve dependencies
2. `melos run analyze` -- static analysis
3. `dart format --set-exit-if-changed .` -- format check (`melos run format` rewrites files instead)
4. `melos run di:check` -- injector regions and test harness match the `pubspec.yaml` declarations
5. `melos run deps:check` -- direct pins that drift or duplicate the dependency barrels
6. `melos run test` -- run tests
7. `melos run graph:cycles` -- check for circular dependencies
8. `melos run graph:validate` -- validate dependency rules

## Fix Common Issues

- **Analysis errors in generated files**: run `melos run build` (generated `*.g.dart`, `*.gr.dart`, `*.config.dart` are gitignored by default; `*.module.dart` is committed).
- **`env.g.dart` fails with `Environment variable not found`**: no `.env` yet. `melos run env:init`, then `melos run env:switch -- development`.
- **`di:check` fails**: `dart run monorepo_toolkit generate host-registry`, then `dart run monorepo_toolkit generate test-harness`.
- **A brick stops with `Nothing was changed`**: see the `archipelago-upgrade` skill.
