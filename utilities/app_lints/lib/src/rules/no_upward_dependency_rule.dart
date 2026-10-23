import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when a lower-level package imports a higher-level one.
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
  'no_upward_dependency',
  'Lower-level packages must not import higher-level packages. '
      "'{0}' (layer: {1}) cannot import '{2}' (layer: {3}). "
      'Dependencies flow downward only: '
      'apps -> features -> infrastructure -> packages -> shared.',
  correctionMessage:
      'Extract shared contracts into a lower-level package, '
      'or restructure to follow the dependency flow.',
);

/// Warns when a lower-level package imports a higher-level one.
///
/// Enforces the dependency flow rule from ADR-006:
/// `apps/ -> features/ -> infrastructure/ -> packages/ -> shared/`
///
/// A package at a given layer may only import from the same layer or below.
/// Both layers come from where the files live in the workspace (see
/// [layerOf]), never from package names, so renamed packages classify
/// correctly and pub packages are never part of the flow.
///
/// Example violation:
/// ```dart
/// // In shared/app_config/lib/src/some_file.dart
/// import 'package:auth_api/auth_api.dart'; // LINT (shared -> features)
/// ```
class NoUpwardDependencyRule() extends AnalysisRule {
  /// Creates a new [NoUpwardDependencyRule].
  this
    : super(
        name: 'no_upward_dependency',
        description:
            "Don't import higher-level packages from lower-level packages.",
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final current = currentLocation(context);
    if (current == null) return;
    registry.addImportDirective(this, _Visitor(this, current));
  }
}

class _Visitor(final NoUpwardDependencyRule rule, final Location current)
    extends SimpleAstVisitor<void> {
  @override
  void visitImportDirective(ImportDirective node) {
    final imported = importedPackage(node, current.root);
    final layer = imported?.layer;
    if (layer == null || layer.index <= current.layer.index) return;
    rule.reportAtNode(
      node,
      arguments: [
        current.package,
        current.layer.name,
        imported!.package,
        layer.name,
      ],
    );
  }
}
