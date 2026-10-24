import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/di_types.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when a feature manifest resolves from GetIt at boot.
const _code = LintCode(
  'no_service_locator_in_manifest',
  'A FeatureManifest must not resolve from GetIt in its constructor, '
      '`isEnabled` or `registerRoutes`.',
  correctionMessage:
      'Take a provider closure from the global module instead, and call it '
      'where the value is needed (a route builder, a claim, `initialize`).',
);

/// Flags every use of a `GetIt` value in a `FeatureManifest` subtype's
/// constructor (including non-`late` field initializers), `isEnabled` getter or
/// `registerRoutes` method, in `features/**/lib/**` (ADR-038).
///
/// The host reads every manifest during pre-launch, so a lookup there builds
/// the feature's graph on the boot path. A closure written in those members
/// is fine: it runs later, when it is called. `initialize()`, `dispose()` and
/// other members may resolve. `FeatureSDK` is a manifest, so eager SDKs are
/// checked too.
///
/// Example violation:
/// ```dart
/// class const PaywallManifest() extends FeatureManifest {
///   @override
///   bool get isEnabled => GetIt.I<PaywallSDK>().isAvailable; // LINT
/// }
/// ```
///
/// Correct usage: the global module passes
/// `isAvailable: () => gh<PaywallSDK>().isAvailable` into the manifest.
class NoServiceLocatorInManifestRule() extends AnalysisRule {
  /// Creates a new [NoServiceLocatorInManifestRule].
  this
    : super(
        name: 'no_service_locator_in_manifest',
        description:
            "Don't resolve from GetIt in a FeatureManifest's constructor, "
            '`isEnabled` or `registerRoutes`.',
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (currentLocation(context)?.layer != Layer.features) return;
    final visitor = _Visitor(this);
    registry
      ..addSimpleIdentifier(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor);
  }
}

class _Visitor(final NoServiceLocatorInManifestRule rule)
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
    if (!_inBootMember(node)) return;
    final type = node
        .thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredFragment
        ?.element
        .thisType;
    if (isOrExtends(type, 'FeatureManifest')) rule.reportAtNode(node);
  }

  /// Whether [node] runs when the manifest is built or read at boot: it sits
  /// in a constructor, an instance field initializer, `isEnabled` or
  /// `registerRoutes`, and not inside a closure.
  bool _inBootMember(AstNode node) {
    for (AstNode? n = node.parent; n != null; n = n.parent) {
      switch (n) {
        case FunctionExpression():
          return false;
        case ConstructorDeclaration() || PrimaryConstructorBody():
          return true;
        // A `late` initializer runs on first read, not at construction.
        case FieldDeclaration(:final isStatic, :final fields):
          return !isStatic && fields.lateKeyword == null;
        case MethodDeclaration(:final name, :final isGetter):
          return isGetter
              ? name.lexeme == 'isEnabled'
              : name.lexeme == 'registerRoutes';
        case ClassDeclaration():
          return false;
      }
    }
    return false;
  }
}
