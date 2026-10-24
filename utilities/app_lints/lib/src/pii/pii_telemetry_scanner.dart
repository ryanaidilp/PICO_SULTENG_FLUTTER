import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:app_lints/src/pii/pii_key_matcher.dart';

/// Finds deny-listed keys in map literals handed to telemetry calls.
///
/// Split out from the lint rule so the AST logic can be exercised directly
/// against a parsed compilation unit in tests, without booting the analysis
/// server plugin.
class const PiiTelemetryScanner({
  /// Method names this scanner inspects.
  final Set<String> methodNames = defaultMethodNames,
}) {
  /// Creates a scanner.
  this;

  /// Telemetry entry points whose arguments are inspected.
  ///
  /// These are the calls through which a payload leaves the device:
  /// analytics events (`track`), monitoring logs (`log`), crash breadcrumbs
  /// (`breadcrumb`), error reports (`recordError`) and blackbox session
  /// events (`captureCustomEvent`), which ship inside a shareable `.bbx`.
  static const Set<String> defaultMethodNames = {
    'track',
    'log',
    'breadcrumb',
    'recordError',
    'captureCustomEvent',
  };

  /// Whether [node] is a telemetry call this rule cares about.
  bool matchesCall(MethodInvocation node) =>
      methodNames.contains(node.methodName.name);

  /// Returns the key expressions in [node]'s arguments that name personal
  /// fields.
  ///
  /// The whole argument subtree is searched, not just top-level map literals,
  /// because the common shape wraps the payload in an event object:
  /// `analytics.track(SignupEvent({'user_email': email}))`. Restricting the
  /// search to direct arguments would miss almost every real call site.
  ///
  /// Only string-literal keys are reported. A computed key cannot be resolved
  /// at author time, and guessing would produce false positives on exactly the
  /// dynamic code the runtime scrubber already covers.
  List<Expression> findViolations(MethodInvocation node) {
    if (!matchesCall(node)) return const [];

    final visitor = _DeniedKeyVisitor(methodNames);
    node.argumentList.accept(visitor);
    return visitor.violations;
  }
}

class _DeniedKeyVisitor(final Set<String> methodNames)
    extends RecursiveAstVisitor<void> {
  final List<Expression> violations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // A nested telemetry call is reported when the rule visits it directly;
    // descending into it here would report its payload twice.
    if (methodNames.contains(node.methodName.name)) return;
    super.visitMethodInvocation(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    final name = _literalStringValue(node.key);
    if (name != null && PiiKeyMatcher.isDenied(name)) violations.add(node.key);
    super.visitMapLiteralEntry(node);
  }

  static String? _literalStringValue(Expression expression) {
    if (expression is SimpleStringLiteral) return expression.value;
    if (expression is AdjacentStrings) return expression.stringValue;
    return null;
  }
}
