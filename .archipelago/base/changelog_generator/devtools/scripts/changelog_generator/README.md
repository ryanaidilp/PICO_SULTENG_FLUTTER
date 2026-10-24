# Changelog Generator

Writes a dated `CHANGELOG.md` section from the commits since the last matching
tag, grouped by Conventional Commit type. Plain text, no network.

```bash
# Commits since the latest v* tag, written under "Unreleased"
dart run monorepo_toolkit changelog

# Name the version, preview without writing
dart run monorepo_toolkit changelog --version 1.4.0 --dry-run

# One package: tags are <package>-v*, commits touching the path only,
# and the entry goes to <package>/CHANGELOG.md
dart run monorepo_toolkit changelog --package packages/auth --version 0.3.0

# Another tag scheme, and keep chore/ci/docs/test/style/build commits
dart run monorepo_toolkit changelog --tag-pattern 'app/v*' --all
```

Groups: Breaking changes (`!` or a `BREAKING CHANGE:` footer), Features, Fixes,
Performance, Other. Commits that are not Conventional Commits land in Other.
With no matching tag, the whole history is used. A version that already has a
heading is left alone; `Unreleased` is rewritten.
