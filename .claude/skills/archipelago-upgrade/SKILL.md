---
name: archipelago-upgrade
description: Use when running an Archipelago brick again (archipelago generate, mason make) on this project, when a brick stops with "Nothing was changed", when merging a newer brick version with archipelago upgrade, or when editing files under .archipelago/ or a package a brick generated.
---

# Upgrading Generated Packages

Packages a brick generated are yours to change. A brick that runs again must not drop those changes, so each brick keeps a **generation record** and stops before it overwrites anything you changed.

## The record

- `.archipelago/generated/<brick>.json`: the brick's version, the vars it ran with (secrets are left out), the package directories it owns, and a fingerprint of every file in them. `feature_monorepo_skeleton` keeps one per feature: `.archipelago/generated/feature_monorepo_skeleton/<feature>.json`.
- `.archipelago/base/<brick>/`: every recorded file as the brick generated it, the base of the 3-way merge.
- `archipelago.yaml` lists each recorded brick's version under `brick_versions`.

Commit all of them with the packages. Never edit them by hand. Fingerprints ignore whitespace and trailing commas (`dart format` is not a change), generated code (`*.g.dart`, `*.module.dart`, ...), `build/`, dot directories and gitignored files.

A brick owns only its packages (directories with a `pubspec.yaml`). Host and workspace files (the app's `pubspec.yaml`, `lib/di/injector.dart`, initializers, `build_prepare.yaml`, the root `pubspec.yaml`, CI files) are edited through marker regions and are never fingerprinted. The scaffold itself (`flutter_modular_monorepo`), `app_scaffold`, `initializer_skeleton`, `state_management`, `ui_kit_component` and `ui_kit_theme` keep no record.

## The drift stop

Before it writes anything, the brick compares its packages with the record and stops when a file was **changed**, **added** (a new file in an owned package) or **deleted**. It lists them, prints `Nothing was changed` and exits with an error. Nothing on disk changed.

| Situation | Do this |
|---|---|
| You changed the packages and want the new version | `archipelago upgrade <brick>` (below) |
| You did not change them (or the changes can go) | `ARCHIPELAGO_FORCE=1 archipelago generate <brick>` (or `ARCHIPELAGO_FORCE=1 mason make <brick> --on-conflict overwrite`): overwrites the template files and records the result. Files you added stay. |
| The project predates the record (the brick stops once, "no record") | Unchanged: `ARCHIPELAGO_FORCE=1` once. Changed: merge by hand (below). |

Never set `ARCHIPELAGO_FORCE=1` to get past a stop you have not read: it overwrites the listed files.

## `archipelago upgrade`

```bash
archipelago upgrade <brick> --dry-run                    # report only
archipelago upgrade <brick>
archipelago upgrade feature_monorepo_skeleton/<feature>  # one feature
```

It generates the new version in `.dart_tool/archipelago_upgrade/` with the recorded vars, then for each file in the brick's packages compares yours, the base and the new output: unchanged files are replaced, files only you changed are kept, files both changed go through `git merge-file`. Files deleted upstream are reported and kept.

- Conflicts keep `<<<<<<< yours` / `>>>>>>> <brick> <version>` markers; the command exits 1 and the record stays at the old version. Resolve the markers, then run the same command again: it merges cleanly and records the new version.
- Options: `--config <file.json>` (vars that override the record, e.g. a secret), `--base-ref <rev>` (a commit with the old generated files, for a record without a base), `--with-deps` (upgrade the recorded bricks it generates first), `--local-bricks <repo>`, `-o <dir>`.
- Host wiring outside the packages (the app's `injector.dart`, `pubspec.yaml`, `build_prepare.yaml`) and shared files are not merged; the brick's CHANGELOG lists what to copy by hand. A kept shared `pubspec.yaml` only gains the new dependencies.
- After it: `melos bootstrap`, `melos run build`, `melos run di:check`, `melos run analyze`, then commit packages, record and base together.

## Merge by hand (no record, or no CLI)

1. Commit your work. Generate the new version in a scratch worktree after deleting the brick's packages there: `git worktree add ../upgrade HEAD && cd ../upgrade && rm -rf <owned dirs> && archipelago generate <brick>`.
2. For each file you changed: `git show <commit-that-generated-it>:<f> > base && git merge-file <f> base ../upgrade/<f>`.
3. Copy new files over, delete files the brick CHANGELOG lists as moved or removed, copy `../upgrade/.archipelago/generated/<brick>.json` and `../upgrade/.archipelago/base/<brick>/`, and the host wiring `git diff HEAD` shows in `../upgrade`.
4. `melos bootstrap && melos run build && melos run analyze`, then `git worktree remove ../upgrade`.

Mason never deletes files: after any upgrade, read the brick's CHANGELOG for moved or removed files.

## Agent files

`.claude/`, `AGENTS.md`, `CLAUDE.md` and the other agent configs are outside every record. A brick that ships a skill writes its own `.claude/skills/<skill>/` again when it runs (Mason asks before it overwrites a file you changed), and adds its row to the skill index in `AGENTS.md` once. `archipelago upgrade` does not merge them.
