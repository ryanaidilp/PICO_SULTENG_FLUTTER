import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:app_lints/app_lints.dart';
import 'package:test/test.dart';

import 'dart_sdk_path.dart';

/// A generated-style workspace, held in memory only.
///
/// Package names are deliberately misleading: the renamed `lumbung_*`
/// packages carry no layer hint, and the pub packages look like workspace
/// layers (`monitoring_api`, `vendor_impl`). The rules must classify them by
/// where they live, not by what they are called.
const _workspace = <String, List<String>>{
  // path relative to the workspace root -> imported packages
  'shared/core': [
    'logger', // pub package
    'monitoring_api', // pub package named like an infrastructure _api
    'lumbung_core', // renamed workspace package in shared/
    'auth_api', // a real upward import: shared -> features
  ],
  'shared/lumbung_core': [],
  'utilities/lumbung_utils': [],
  'packages/lumbung_ui_kit': ['lumbung_core', 'kirana'],
  'features/auth/auth_api': [
    'lumbung_core',
    'lumbung_utils',
    'home_api',
    'equatable',
    'monitoring_api',
    'dio',
    'lumbung_ui_kit',
  ],
  'features/auth/auth_impl': [
    'auth_api',
    'lumbung_ui_kit',
    'home_impl',
    'vendor_impl', // pub package named like a workspace _impl
  ],
  'features/home/home_api': [],
  'features/home/home_impl': [],
  'apps/kirana': ['auth_impl', 'lumbung_ui_kit'],
};

const _pubPackages = [
  'logger',
  'monitoring_api',
  'vendor_impl',
  'dio',
  'equatable',
];

void main() {
  late _Fixture fixture;

  setUpAll(() => fixture = _Fixture());

  group('no_upward_dependency', () {
    final rule = NoUpwardDependencyRule();

    test('ignores pub packages, whatever their name', () async {
      final flagged = await fixture.lint(rule, 'shared/core');
      expect(flagged, isNot(contains('logger')));
      expect(flagged, isNot(contains('monitoring_api')));
    });

    test('classifies a renamed shared package by its folder', () async {
      expect(
        await fixture.lint(rule, 'shared/core'),
        isNot(contains('lumbung_core')),
      );
    });

    test('still flags a real upward import', () async {
      expect(await fixture.lint(rule, 'shared/core'), ['auth_api']);
    });

    test('flags an import of a renamed app package', () async {
      expect(await fixture.lint(rule, 'packages/lumbung_ui_kit'), ['kirana']);
    });

    test('allows downward imports', () async {
      expect(await fixture.lint(rule, 'features/auth/auth_impl'), isEmpty);
      expect(await fixture.lint(rule, 'apps/kirana'), isEmpty);
    });
  });

  group('api_no_external_deps', () {
    test('allows shared, utilities and workspace _api packages by location, '
        'and flags pub and higher-layer packages', () async {
      expect(
        await fixture.lint(ApiNoExternalDepsRule(), 'features/auth/auth_api'),
        ['monitoring_api', 'dio', 'lumbung_ui_kit'],
      );
    });

    test('does not apply to non-api packages', () async {
      expect(
        await fixture.lint(ApiNoExternalDepsRule(), 'shared/core'),
        isEmpty,
      );
    });
  });

  group('no_impl_cross_import', () {
    test(
      'flags a workspace impl, ignores a pub package named *_impl',
      () async {
        expect(
          await fixture.lint(
            NoImplCrossImportRule(),
            'features/auth/auth_impl',
          ),
          ['home_impl'],
        );
      },
    );
  });
}

/// Resolves the [_workspace] fixture and runs a rule over one package.
class _Fixture() {
  final root = '${Directory.current.path}/.dart_tool/layer_rules_fixture';
  late final provider = OverlayResourceProvider(
    PhysicalResourceProvider.INSTANCE,
  );
  late final AnalysisContextCollection collection = () {
    final ws = '$root/ws';
    final packages = <Map<String, String>>[];

    void write(String path, String content) =>
        provider.setOverlay(path, content: content, modificationStamp: 0);

    void addPackage(String name, String dir, List<String> imports) {
      packages.add({
        'name': name,
        'rootUri': Uri.directory(dir).toString(),
        'packageUri': 'lib/',
      });
      write('$dir/pubspec.yaml', 'name: $name\nresolution: workspace\n');
      write(
        '$dir/lib/$name.dart',
        [
          for (final import in imports)
            "import 'package:$import/$import.dart';",
          'const int marker = 0;',
        ].join('\n'),
      );
    }

    _workspace.forEach(
      (path, imports) => addPackage(path.split('/').last, '$ws/$path', imports),
    );
    for (final name in _pubPackages) {
      addPackage(name, '$root/pub_cache/$name-1.0.0', const []);
    }

    write('$ws/pubspec.yaml', 'name: ws\nworkspace:\n  - shared/core\n');
    write('$ws/analysis_options.yaml', '');
    write(
      '$ws/.dart_tool/package_config.json',
      jsonEncode({'configVersion': 2, 'packages': packages}),
    );
    return AnalysisContextCollection(
      includedPaths: [ws],
      resourceProvider: provider,
      sdkPath: dartSdkPath(),
    );
  }();

  /// The package names whose imports [rule] flags in the package at [path].
  Future<List<String>> lint(AnalysisRule rule, String path) async {
    final name = path.split('/').last;
    final filePath = '$root/ws/$path/lib/$name.dart';
    final result =
        await collection
                .contextFor(filePath)
                .currentSession
                .getResolvedUnit(filePath)
            as ResolvedUnitResult;

    final file = provider.getFile(filePath);
    final listener = RecordingDiagnosticListener();
    final reporter = DiagnosticReporter(
      listener,
      result.libraryElement.firstFragment.source,
    );
    final registry = _ImportRegistry();
    rule
      ..reporter = reporter
      ..registerNodeProcessors(
        registry,
        _RuleContext(
          RuleContextUnit(
            file: file,
            content: result.content,
            diagnosticReporter: reporter,
            unit: result.unit,
          ),
          result.libraryElement,
        ),
      );

    final imports = result.unit.directives.whereType<ImportDirective>();
    final visitor = registry.visitor;
    if (visitor != null) {
      for (final import in imports) {
        import.accept(visitor);
      }
    }
    return [
      for (final diagnostic in listener.diagnostics)
        imports
            .firstWhere((i) => i.offset == diagnostic.offset)
            .uri
            .stringValue!
            .split(RegExp('[:/]'))[1],
    ];
  }
}

class _RuleContext(
  @override final RuleContextUnit definingUnit,
  @override final LibraryElement? libraryElement,
) implements RuleContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImportRegistry() implements RuleVisitorRegistry {
  AstVisitor<void>? visitor;

  @override
  void addImportDirective(
    AbstractAnalysisRule rule,
    AstVisitor<void> visitor,
  ) => this.visitor = visitor;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
