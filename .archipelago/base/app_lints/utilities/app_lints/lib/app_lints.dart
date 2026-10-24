/// Custom lint rules for enforcing architecture and privacy conventions.
///
/// Architecture rules, based on ADR-006 (Dependency Graph Enforcement):
///
/// - `no_impl_cross_import` -- Prevents `*_impl` packages from importing
///   other `*_impl` packages.
/// - `api_no_external_deps` -- Restricts `*_api` packages to only allowed
///   dependencies.
/// - `no_upward_dependency` -- Enforces downward-only dependency flow.
///
/// Privacy rule:
///
/// - `no_pii_in_telemetry` -- Flags personally-identifying keys in map
///   literals passed to `track`, `log`, `breadcrumb`, `recordError` and
///   `captureCustomEvent`.
///
/// DI rules, for `features/**` only:
///
/// - `no_service_locator_outside_di` -- Flags `GetIt` uses outside
///   `lib/src/di/` and `MicroPackageModule`s.
/// - `feature_global_module_allowlist` -- Flags registrations in a feature
///   global module other than its manifest, its own SDK, and annotated ports.
/// - `no_service_locator_in_manifest` -- Flags `GetIt` uses in a
///   `FeatureManifest`'s constructor, `isEnabled` and `registerRoutes`.
///
/// ## Usage
///
/// Enable the plugin and its rules in the root `analysis_options.yaml`. See
/// `utilities/app_lints/README.md` for the exact config shape and why these
/// rules are IDE-time advisory only — the CI-enforced gate for the
/// architecture rules is `dependency_graph`'s `graph validate` command.
library;

export 'src/pii/pii_key_matcher.dart';
export 'src/pii/pii_telemetry_scanner.dart';
export 'src/rules/api_no_external_deps_rule.dart';
export 'src/rules/feature_global_module_allowlist_rule.dart';
export 'src/rules/no_impl_cross_import_rule.dart';
export 'src/rules/no_pii_in_telemetry_rule.dart';
export 'src/rules/no_service_locator_in_manifest_rule.dart';
export 'src/rules/no_service_locator_outside_di_rule.dart';
export 'src/rules/no_upward_dependency_rule.dart';
