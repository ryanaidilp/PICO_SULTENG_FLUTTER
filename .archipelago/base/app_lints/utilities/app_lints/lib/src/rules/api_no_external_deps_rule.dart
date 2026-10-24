import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when an `*_api` package imports a non-allowed package.
///
/// Severity is left at the plugin lint default (INFO) rather than promoted
/// to ERROR. Unlike built-in lints, plugin-contributed diagnostics cannot
/// be re-promoted via `analysis_options.yaml`'s `analyzer: errors:` block
/// (that block only recognizes analyzer-native diagnostic codes — see the
/// NOTE in the root `analysis_options.yaml`); it would need to be set here
/// on the `LintCode` itself via its `severity` parameter. This plugin is
/// intentionally IDE-time advisory only — the authoritative, CI-enforced
/// gate for this rule is `dependency_graph`'s `graph validate` command
/// (see its doc comment for why: one-shot `dart analyze` does not
/// reliably wait for plugin diagnostics before exiting).
const _code = LintCode(
  'api_no_external_deps',
  "API packages can only import from 'dart:', 'package:flutter/', "
      "'shared/', 'utilities/', 'package:meta/', and other '*_api' packages. "
      "Found import of '{0}'.",
  correctionMessage:
      'Move this dependency to the impl package, or extract a shared '
      'contract into an _api package.',
);

/// Warns when an `*_api` package file imports a non-allowed package.
///
/// Allowed imports for `*_api` packages:
/// - `dart:` core libraries
/// - `package:flutter/` SDK
/// - `package:meta/` annotations
/// - Other `*_api` workspace packages
/// - Workspace packages in the `shared/` or `utilities/` folder, whatever
///   their name
/// - A fixed list of annotation and codegen pub packages
///
/// Workspace packages are recognised by where their files resolve (see
/// [layerOf]), so a pub package named `*_api` is still an external
/// dependency, and a renamed shared package is still shared.
///
/// This enforces rule 1 from ADR-006.
///
/// Example violation:
/// ```dart
/// // In auth_api/lib/src/models/user.dart
/// import 'package:dio/dio.dart'; // LINT
/// ```
class ApiNoExternalDepsRule() extends AnalysisRule {
  /// Creates a new [ApiNoExternalDepsRule].
  this
    : super(
        name: 'api_no_external_deps',
        description: "Don't import non-allowed packages from '*_api' packages.",
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final current = currentLocation(context);
    if (current == null || !current.package.endsWith('_api')) return;
    registry.addImportDirective(this, _Visitor(this, current));
  }
}

/// External packages that `*_api` packages may import.
const _allowedExternalPackages = {
  'flutter',
  'meta',
  'freezed_annotation',
  'json_annotation',
  'equatable',
  'collection',
  'injectable',
  'auto_route',
};

class _Visitor(final ApiNoExternalDepsRule rule, final Location current)
    extends SimpleAstVisitor<void> {
  @override
  void visitImportDirective(ImportDirective node) {
    // dart:, relative and unresolved imports are not checked.
    final imported = importedPackage(node, current.root);
    if (imported == null) return;
    final (:package, :layer) = imported;
    final allowed = switch (layer) {
      Layer.shared => true,
      null => _allowedExternalPackages.contains(package),
      _ => package == current.package || package.endsWith('_api'),
    };
    if (!allowed) rule.reportAtNode(node, arguments: [package]);
  }
}
