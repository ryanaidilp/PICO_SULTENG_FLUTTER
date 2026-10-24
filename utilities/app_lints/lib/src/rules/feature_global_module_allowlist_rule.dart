import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/rules/di_types.dart';
import 'package:app_lints/src/rules/workspace_layer.dart';

/// Lint code reported when a feature global module registers an internal.
const _code = LintCode(
  'feature_global_module_allowlist',
  "'{0}' is registered into the app-wide container by a feature global "
      'module.',
  correctionMessage:
      "Register it in the feature's local DI instead. If other code really "
      'resolves it from the root (a port the feature owns), add '
      '`// di-global: <reason>` on the same line or the line above.',
);

/// `GetIt.register*` and the `GetItHelper` (`gh`) registration methods.
final _registration = RegExp('^(register|factory|lazySingleton|singleton)');

final _annotation = RegExp(r'//\s*di-global:\s*\S');

/// Flags each registration inside `MicroPackageModule.init` in `features/**`,
/// unless it registers one of:
///
/// - a `FeatureManifest`;
/// - the feature's own SDK, declared in the same `features/<name>/` folder
///   (its `_api` package, or the package itself for a single-package
///   feature): a `FeatureSDK` subtype (eager), or a lazy port whose name
///   ends in `SDK`;
/// - anything on a line annotated `// di-global: <reason>`, or directly below
///   a comment line of its own with that annotation. The reason must not be
///   empty.
///
/// Example violation:
/// ```dart
/// class AuthImplGlobalModule() extends MicroPackageModule {
///   @override
///   FutureOr<void> init(GetItHelper gh) {
///     GetIt.I.registerLazySingleton<LoginRepository>(...); // LINT
///     GetIt.I.registerSingleton<AuthSDK>(AuthSDKImpl.create()); // OK
///     gh.lazySingleton<HomeSDK>(HomeSDKImpl.new); // OK in features/home
///   }
/// }
/// ```
class FeatureGlobalModuleAllowlistRule() extends AnalysisRule {
  /// Creates a new [FeatureGlobalModuleAllowlistRule].
  this
    : super(
        name: 'feature_global_module_allowlist',
        description:
            'Feature global modules register only their manifest, their own '
            'SDK, and annotated ports.',
      );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final location = currentLocation(context);
    if (location?.layer != Layer.features) return;
    registry.addMethodInvocation(this, _Visitor(this, context, location!.root));
  }
}

class _Visitor(
  final FeatureGlobalModuleAllowlistRule rule,
  final RuleContext context,
  final String root,
) extends SimpleAstVisitor<void> {
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_registration.hasMatch(node.methodName.name)) return;
    final target = node.realTarget?.staticType;
    if (!isGetIt(target) &&
        !isOrExtends(target, 'GetItHelper', package: 'injectable')) {
      return;
    }
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method?.name.lexeme != 'init' || !inMicroPackageModule(method!)) {
      return;
    }
    final type = node.typeArgumentTypes?.firstOrNull;
    if (_allowed(type) || _annotated(node)) return;
    rule.reportAtNode(
      node.methodName,
      arguments: [type?.getDisplayString() ?? node.methodName.name],
    );
  }

  bool _allowed(DartType? type) =>
      isOrExtends(type, 'FeatureManifest') ||
      (type is InterfaceType &&
          (isOrExtends(type, 'FeatureSDK') ||
              (type.element.name ?? '').endsWith('SDK')) &&
          _inThisFeature(type));

  bool _inThisFeature(DartType type) {
    final declared =
        (type as InterfaceType).element.library.firstFragment.source.fullName;
    final here = _feature(context.definingUnit.file.path);
    return here != null && here == _feature(declared);
  }

  /// `<name>` of `<root>/features/<name>/...`, or null.
  String? _feature(String path) {
    final file = path.replaceAll(r'\', '/');
    final prefix = '${root.replaceAll(r'\', '/')}/features/';
    if (!file.startsWith(prefix)) return null;
    return file.substring(prefix.length).split('/').first;
  }

  bool _annotated(MethodInvocation node) {
    final unit = context.currentUnit;
    if (unit == null) return false;
    final lines = unit.unit.lineInfo;
    String text(int i) => unit.content
        .substring(
          lines.getOffsetOfLine(i),
          i + 1 < lines.lineCount
              ? lines.getOffsetOfLine(i + 1)
              : unit.content.length,
        )
        .trim();

    final line = lines.getLocation(node.methodName.offset).lineNumber - 1;
    if (_annotation.hasMatch(text(line))) return true;
    // The line above counts only as a comment line of its own, so a trailing
    // annotation never covers the next statement.
    if (line == 0) return false;
    final above = text(line - 1);
    return above.startsWith('//') && _annotation.hasMatch(above);
  }
}
