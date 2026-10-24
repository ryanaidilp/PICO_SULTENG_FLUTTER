#!/usr/bin/env bash
# Analyze and test the workspace for CI. FULL=true runs every package;
# otherwise only the packages changed since $BASE plus their dependents
# (devtools/ci/scope.sh computes both). Uses the Enterprise `affected` tool
# when the project has it, melos --diff otherwise.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

dart pub get
dart run melos bootstrap
dart run melos run env:init
dart run melos run env:switch -- development
# *.g.dart/*.config.dart/*.gr.dart and the asset constants are gitignored:
# generate them before analyzing. envied needs the .env from env:switch.
dart run melos run build
dart run melos run asset-gen:generate

if [[ ${FULL:-true} == true ]]; then
  dart run melos run analyze
  dart run melos run test
elif [[ -d devtools/scripts/affected ]]; then
  dart run monorepo_toolkit affected analyze --base "$BASE" --no-fatal-infos --no-fatal-warnings
  dart run monorepo_toolkit affected test --base "$BASE" --coverage
else
  # No --dir-exists: melos applies it before --diff/--include-dependents, so a
  # changed package without lib/ or test/ would drop its dependents. Each
  # package checks for the directory itself instead.
  dart run melos exec --diff="$BASE" --include-dependents -- \
    '[ ! -d lib ] || flutter analyze --no-fatal-infos --no-fatal-warnings lib'
  # Exit 79: every test in the package is golden-tagged (see melos test:select).
  dart run melos exec --diff="$BASE" --include-dependents -- \
    '[ ! -d test ] || flutter test --coverage --exclude-tags golden || [ $? -eq 79 ]'
fi
