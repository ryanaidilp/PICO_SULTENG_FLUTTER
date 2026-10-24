import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:app_lints/src/rules/api_no_external_deps_rule.dart';
import 'package:app_lints/src/rules/feature_global_module_allowlist_rule.dart';
import 'package:app_lints/src/rules/no_impl_cross_import_rule.dart';
import 'package:app_lints/src/rules/no_pii_in_telemetry_rule.dart';
import 'package:app_lints/src/rules/no_service_locator_in_manifest_rule.dart';
import 'package:app_lints/src/rules/no_service_locator_outside_di_rule.dart';
import 'package:app_lints/src/rules/no_upward_dependency_rule.dart';

/// The analyzer plugin instance.
///
/// This top-level variable is required by the Dart analyzer plugin system.
final plugin = AppLintsPlugin();

/// Custom lint rules plugin for the application.
///
/// This plugin provides custom lint rules to enforce architecture conventions
/// defined in ADR-006 (Dependency Graph Enforcement):
///
/// - [NoImplCrossImportRule] -- Prevents `*_impl` packages from importing
///   other `*_impl` packages.
/// - [ApiNoExternalDepsRule] -- Restricts `*_api` packages to only allowed
///   dependencies (shared, utilities, other _api, dart:, flutter, meta).
/// - [NoUpwardDependencyRule] -- Enforces downward-only dependency flow
///   (apps -> features -> infrastructure -> packages -> shared).
///
/// It also provides a privacy rule that is not an ADR-006 concern:
///
/// - [NoPiiInTelemetryRule] -- Flags personally-identifying keys in map
///   literals passed to `track`, `log`, `breadcrumb`, `recordError` and
///   `captureCustomEvent`.
///
/// And three DI rules for feature code:
///
/// - [NoServiceLocatorOutsideDiRule] -- Flags `GetIt` uses in feature
///   libraries outside `lib/src/di/` and `MicroPackageModule`s.
/// - [FeatureGlobalModuleAllowlistRule] -- Flags registrations in a feature
///   `MicroPackageModule.init` other than its manifest, its own SDK, and
///   lines annotated `// di-global: <reason>`.
/// - [NoServiceLocatorInManifestRule] -- Flags `GetIt` uses in a
///   `FeatureManifest`'s constructor, `isEnabled` and `registerRoutes`.
class AppLintsPlugin() extends Plugin {
  @override
  String get name => 'app_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(NoImplCrossImportRule())
      ..registerLintRule(ApiNoExternalDepsRule())
      ..registerLintRule(NoUpwardDependencyRule())
      ..registerLintRule(NoPiiInTelemetryRule())
      ..registerLintRule(NoServiceLocatorOutsideDiRule())
      ..registerLintRule(FeatureGlobalModuleAllowlistRule())
      ..registerLintRule(NoServiceLocatorInManifestRule());
  }
}
