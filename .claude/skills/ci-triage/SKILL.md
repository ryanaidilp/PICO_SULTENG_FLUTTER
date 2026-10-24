---
name: ci-triage
description: Use when a CI run of this project fails, is skipped, or tested less (or more) than expected - the CI workflow, the `ci-ok` check, devtools/ci/scope.sh or devtools/ci/test.sh - or before changing the generated CI.
---

# CI Triage

The generated CI analyzes and tests what a change can break, once per change. Read the run's **scope** output first: most surprises are scope decisions, not test failures.

## How a run is shaped

1. **scope** (`devtools/ci/scope.sh`) prints four values:
   - `full=true`: test every package. Set for PRs/MRs into `main`, from `release/*` or `hotfix/*`, manual and scheduled runs, no usable diff base (first or force push), or a change to a workspace-wide file: `pubspec.yaml`/`pubspec.lock` at the root, `analysis_options.yaml`, `build_prepare.yaml`, `flavors.yaml`, `devtools/ci/`, the workflow files.
   - `base=<sha>`: the diff base. A PR/MR uses the merge base with its target; a push uses the last commit this workflow passed on the branch, else the push's before commit.
   - `version_only=true`: only `version:` lines in `pubspec.yaml` files and `CHANGELOG.md` changed, or nothing did (a back-merge). Tests are skipped.
   - `code=false`: docs-only (`*.md`, `docs/`), or the push of a merged PR/MR whose own run already tested it. Tests are skipped.
2. **test** (`devtools/ci/test.sh`): `dart pub get`, `melos bootstrap`, `env:init`, `env:switch -- development`, `melos run build`, `melos run asset-gen:generate` (generated code and asset constants are gitignored, so CI generates them). Then:
   - `full=true`: `melos run analyze` and `melos run test`.
   - otherwise, with the `affected` tool installed (`devtools/scripts/affected`): `monorepo_toolkit affected analyze|test --base $BASE`.
   - otherwise: `melos exec --diff=$BASE --include-dependents` running `flutter analyze` and `flutter test --exclude-tags golden` per package.
   Golden tests never run here; run them with `melos run test:golden`.
3. **ci-ok** (`.github/workflows/ci.yml`) runs always. It fails when scope failed or a test job failed, and passes when tests were skipped on purpose. It is the one check to require in branch protection; requiring `test` would block every skipped run.

Triggers: `pull_request` into `develop` and `main`, `push` to `develop`, `workflow_dispatch` (always full). A newer run of the same ref cancels the older one.

Reproduce the scope locally: `CI_SCOPE_BASE=$(git merge-base origin/develop HEAD) bash devtools/ci/scope.sh`. Reproduce the test step: `FULL=false BASE=<sha> bash devtools/ci/test.sh`.

## Symptom -> cause

| Symptom | Cause and fix |
|---|---|
| Tests skipped on a PR | `version_only=true` or `code=false`. Expected for version bumps, back-merges and docs. |
| The push after a merge tested nothing | Expected: the PR run tested it. On GitLab, squash and fast-forward merges are tested again. |
| A PR into `develop` ran everything | A workspace-wide file changed, or it comes from `release/*`/`hotfix/*`. |
| A broken package was not tested | It is not a dependent of anything changed since `base`. Check the `base` sha in the scope log; a missing dependency edge in its `pubspec.yaml` hides it. |
| `No passing ... run found` warning | First push to the branch, or the API failed: the diff starts at the push's before commit. Commits of a cancelled earlier run are not retested; run the workflow by hand. |
| `Environment variable not found for field ...` | envied found no `.env`, or a field in `shared/app_config/lib/src/env/env.dart` has no key in the env files. Add keys with `dart run monorepo_toolkit env add KEY`, never by editing `env.dart` alone. |
| `Undefined name` / missing `*.g.dart` | Codegen failed earlier in the log; scroll up to the first `build_runner` error. |
| Analyzer passes locally, fails in CI | Local generated files are stale. `melos run build`, then `melos run analyze`. |
| `MissingPluginException` in `injector_test.dart` | A package does platform I/O during DI init without a test prerequisite (see the `feature-di-registration` skill). |
| `di:check` style failure, injector out of date | `dart run monorepo_toolkit generate host-registry` and `generate test-harness`, then commit. |

## Pro checks

`.github/workflows/pr-checks.yml` (or the `guard` and `build` stages in `.gitlab-ci.yml`) runs on PRs into `main`, release and hotfix PRs, and manual runs:

- `size-guard` (`monorepo_toolkit size-guard check --changed-only`): a committed file over the threshold in `size_guard.yaml`.
- `detect-new-library`: a new dependency that is not in the baseline. Approve it by updating the baseline.
- `android-size-analysis` / `ios-size-analysis`: the release build grew past its baseline.
- `android-permission-guard` / `ios-permission-guard`: a new platform permission compared with the baseline.

Accept an intended change by running the manual **update-baselines** workflow, then rerun the check.

## Before changing the CI

Keep `ci-ok` (or the GitLab `test` job) as the required check, keep `fetch-depth: 0` (the diff needs history), and run the scope script locally on a few branches before you push. `devtools/ci/` and the workflow files are workspace-wide inputs, so the change itself runs the full suite.
