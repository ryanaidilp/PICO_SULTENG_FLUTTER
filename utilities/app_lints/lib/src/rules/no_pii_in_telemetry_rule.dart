import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/pii/pii_telemetry_scanner.dart';

/// Lint code reported when a telemetry payload names a personal field.
const _code = LintCode(
  'no_pii_in_telemetry',
  'This key names personal data and must not be sent to a telemetry vendor.',
  correctionMessage:
      'Remove the property, or replace it with a non-identifying value (an '
      'opaque user ID, a bucketed range, a boolean). The runtime scrubber '
      'will redact it anyway — sending it is a bug, not a fallback.',
);

/// Flags deny-listed keys in map literals passed to `track`, `log`,
/// `breadcrumb`, `recordError` and `captureCustomEvent`.
///
/// The runtime scrubber in `consent_api` already redacts these before they
/// reach a vendor, so this rule exists to catch the mistake where it is cheap
/// to fix — in review, next to the code that introduced it — rather than
/// leaving developers to wonder why a property they added shows up as
/// `[redacted]` in the vendor console.
///
/// Example violation:
/// ```dart
/// analytics.track(SignupEvent({'user_email': user.email})); // LINT
/// monitoring.breadcrumb('checkout', data: {'phoneNumber': phone}); // LINT
/// ```
///
/// Correct usage:
/// ```dart
/// analytics.track(SignupEvent({'user_id': user.id}));
/// monitoring.breadcrumb('checkout', data: {'has_phone': phone != null});
/// ```
class NoPiiInTelemetryRule() extends AnalysisRule {
  /// Creates a new [NoPiiInTelemetryRule].
  this
    : super(
        name: 'no_pii_in_telemetry',
        description:
            "Don't put personally-identifying keys in telemetry payloads.",
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addMethodInvocation(this, _Visitor(this));
}

class _Visitor(final NoPiiInTelemetryRule rule) extends SimpleAstVisitor<void> {
  final PiiTelemetryScanner scanner = const PiiTelemetryScanner();

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      scanner.findViolations(node).forEach(rule.reportAtNode);
}
