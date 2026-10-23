# Changelog

Write a CHANGELOG.md entry from the commits since the last tag, grouped by Conventional Commit type.

## Input

$ARGUMENTS — optional: `--version <x.y.z>`, `--package <path>`, `--tag-pattern <glob>`, `--all`, `--dry-run`

## Commands

```bash
# Preview the entry under "Unreleased"
dart run monorepo_toolkit changelog --dry-run

# Write the entry for a release
dart run monorepo_toolkit changelog --version 1.4.0

# One package (tags <package>-v*, commits under the path, <package>/CHANGELOG.md)
dart run monorepo_toolkit changelog --package packages/auth --version 0.3.0
```

Groups: Breaking changes, Features, Fixes, Performance, Other. chore, ci, docs, test, style and build commits are left out unless `--all`. A version that already has a heading is not rewritten; `Unreleased` is.
