import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/di_types.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when feature code reads a `GetIt` value outside DI.
const _code = LintCode(
  'no_service_locator_outside_di',
  'Feature code must not resolve dependencies from GetIt outside its DI '
      'files.',
  correctionMessage:
      'Take the dependency as a constructor parameter, and resolve it in '
      "the feature's lib/src/di/ files or its MicroPackageModule.",
);

/// Flags every use of a `GetIt` value in `features/**/lib/**` outside
/// `lib/src/di/**` and outside `MicroPackageModule` classes.
///
/// The type is resolved through the element model, so `GetIt.I`,
/// `GetIt.instance`, a top-level `getIt` alias, a feature accessor like
/// `authGetIt` and a local `final getIt = GetIt.instance` are all caught.
/// Tests are exempt: they are not `package:` libraries. Apps, infrastructure
/// and shared code are out of scope; the host composition root and its
/// initializers live in `apps/`.
///
/// Example violation:
/// ```dart
/// // features/home/home_impl/lib/src/presentation/home_page.dart
/// await GetIt.I<AuthSDK>().logout(); // LINT
/// ```
///
/// Correct usage: the page takes `AuthSDK` in its constructor, and the
/// feature's DI wiring passes it in.
class NoServiceLocatorOutsideDiRule() extends AnalysisRule {
  /// Creates a new [NoServiceLocatorOutsideDiRule].
  this
    : super(
        name: 'no_service_locator_outside_di',
        description:
            "Don't use GetIt as a service locator in feature code outside DI "
            'files.',
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (currentLocation(context)?.layer != Layer.features) return;
    if (isDiFile(context.definingUnit.file.path)) return;
    final visitor = _Visitor(this);
    registry
      ..addSimpleIdentifier(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor);
  }
}

class _Visitor(final NoServiceLocatorOutsideDiRule rule)
    extends SimpleAstVisitor<void> {
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // `GetIt.I` and `a.getIt` are reported once, on the whole expression.
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.identifier == node) return;
    if (parent is PropertyAccess && parent.propertyName == node) return;
    _check(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => _check(node);

  @override
  void visitPropertyAccess(PropertyAccess node) => _check(node);

  void _check(Expression node) {
    if (!isGetIt(node.staticType)) return;
    if (node.thisOrAncestorOfType<Comment>() != null) return;
    if (inMicroPackageModule(node)) return;
    rule.reportAtNode(node);
  }
}
