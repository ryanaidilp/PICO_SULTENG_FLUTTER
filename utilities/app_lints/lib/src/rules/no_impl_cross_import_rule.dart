import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when an `*_impl` package imports another `*_impl` package.
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
  'no_impl_cross_import',
  'Impl packages must not import other impl packages. '
      "Use the corresponding '*_api' package for cross-feature communication.",
  correctionMessage:
      "Replace this import with the equivalent '*_api' package import.",
);

/// Warns when a `*_impl` package imports another `*_impl` package.
///
/// Only `*_api` imports are allowed for cross-feature communication.
/// This enforces rule 3 from ADR-006: no sideways dependencies between
/// `*_impl` packages.
///
/// Only workspace packages count: a pub package whose name ends in `_impl`
/// is not one of ours (see [layerOf]).
///
/// Example violation:
/// ```dart
/// // In auth_impl/lib/src/some_file.dart
/// import 'package:home_impl/home_impl.dart'; // LINT
/// ```
///
/// Correct usage:
/// ```dart
/// // In auth_impl/lib/src/some_file.dart
/// import 'package:home_api/home_api.dart'; // OK
/// ```
class NoImplCrossImportRule() extends AnalysisRule {
  /// Creates a new [NoImplCrossImportRule].
  this
    : super(
        name: 'no_impl_cross_import',
        description:
            "Don't import '*_impl' packages from other '*_impl' packages.",
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final current = currentLocation(context);
    if (current == null || !current.package.endsWith('_impl')) return;
    registry.addImportDirective(this, _Visitor(this, current));
  }
}

class _Visitor(final NoImplCrossImportRule rule, final Location current)
    extends SimpleAstVisitor<void> {
  @override
  void visitImportDirective(ImportDirective node) {
    final imported = importedPackage(node, current.root);
    if (imported == null || imported.layer == null) return;
    if (imported.package != current.package &&
        imported.package.endsWith('_impl')) {
      rule.reportAtNode(node);
    }
  }
}
