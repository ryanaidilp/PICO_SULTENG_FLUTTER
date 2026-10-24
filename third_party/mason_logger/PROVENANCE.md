# Vendored `mason_logger` -- provenance & removal condition

- **Replaces:** `mason_logger` `0.3.5` (latest on pub.dev as of 2026-08-07).
- **Source of this copy:** `packages/mason_logger` from
  `davidlondono/mason` @ `604c81458e69bfcece6062368fab68440a2163ab`
  (the head commit of upstream PR
  [felangel/mason#1681](https://github.com/felangel/mason/pull/1681),
  "chore(mason_logger): bump win32 to v6", opened 2026-07-27, still
  **open/unmerged** as of this vendoring).
- **Why:** `device_info_plus`/`network_info_plus`/`package_info_plus`/
  `share_plus`'s current majors require `win32 ^6.0.1+`. In this project's
  pub workspace, forcing `win32` to 6.x breaks `flutter_flavorizr` at Dart
  compile time because it transitively depends on `mason_logger`, and
  published `mason_logger` (0.3.5) still requires `win32 ^5.11.0` --
  its `windows_terminal.dart` FFI code does not compile against win32
  6.x's `Win32Result<HANDLE>` API.
- **What changed vs. published 0.3.5:** `windows_terminal.dart` reworked
  for win32 6's type-safe `HANDLE`/`CONSOLE_MODE` wrapper types, `win32`
  dependency bumped to `^6.3.0`, Dart SDK floor raised to `>=3.10.0 <4.0.0`
  (compatible with this workspace's `>=3.12.0` floor). Diff:
  `gh pr diff 1681 --repo felangel/mason`.
- **Trimmed from upstream:** only `lib/`, `pubspec.yaml`, `LICENSE`,
  `README.md` are vendored (no `test/`, `example/`, `analysis_options.yaml`,
  `.gitignore`, `coverage_badge.svg` -- not needed to consume the package
  as a path dependency).
- **Known additional risk (read before relying on this in production):**
  mason_logger `0.3.4` previously shipped this exact same `win32 ^6.0.0`
  bump (upstream PR #1650) and `0.3.5` **reverted** it: "due to use of
  native assets this was breaking hook execution on windows" (see
  upstream `CHANGELOG.md`). PR #1681 fixes the Dart *compile-time* FFI
  break this ticket hit, but does not mention addressing that earlier
  *runtime* native-assets/hook-execution regression on Windows. This
  vendored copy has only been verified to **compile and run
  `flutter_flavorizr`/`melos run build` on macOS**, not on a real Windows
  host -- Windows users of a generated app's dev tooling may hit the
  original 0.3.4 regression again. Treat this as a stronger reason to
  revert to a real published release as soon as one exists, not as a
  green light to treat this as risk-free.
- **Removal condition:** once `felangel/mason#1681` (or an equivalent fix)
  merges **and** a new `mason_logger` version is published to pub.dev with
  it, delete this directory and the corresponding `path:`
  `dependency_overrides` entry in `pubspec.yaml`, and let the normal
  version-solver pick up the real release.
