import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// The analyzer's own visitor, so every node type the rules use is dispatched.
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:app_lints/app_lints.dart';
import 'package:test/test.dart';

import 'dart_sdk_path.dart';

/// Minimal stand-ins for the pub packages the rules resolve by element.
const _pub = <String, String>{
  'get_it': '''
class GetIt {
  GetIt._();
  static final GetIt instance = GetIt._();
  static GetIt get I => instance;
  T call<T extends Object>() => throw 0;
  T get<T extends Object>() => throw 0;
  bool isRegistered<T extends Object>() => false;
  void registerSingleton<T extends Object>(T instance) {}
  void registerLazySingleton<T extends Object>(T Function() factory) {}
}
''',
  'injectable': '''
import 'dart:async';
import 'package:get_it/get_it.dart';
export 'package:get_it/get_it.dart';
class GetItHelper {
  T call<T extends Object>() => throw 0;
  void lazySingleton<T extends Object>(T Function() factory) {}
}
abstract class MicroPackageModule {
  FutureOr<void> init(GetItHelper gh);
}
''',
};

/// Workspace packages: path -> library source (`lib/<name>.dart`).
const _workspace = <String, String>{
  'shared/feature_sdk': '''
abstract class FeatureSDK {}
abstract class FeatureManifest {}
''',
  'shared/core': '''
import 'package:get_it/get_it.dart';
// Not a feature: out of scope.
final x = GetIt.I<Object>();
''',
  'features/home/home_api': '''
import 'package:feature_sdk/feature_sdk.dart';
abstract class HomeSDK implements FeatureSDK {}
''',
  'features/auth/auth_api': '''
import 'package:feature_sdk/feature_sdk.dart';
abstract class AuthSDK implements FeatureSDK {}
abstract class AuthTokenPort {}
abstract class AuthPortSDK {}
''',
  'features/auth/auth_impl': '''
export 'src/di/auth_global_module.dart';
export 'src/presentation/login_page.dart';
''',
};

/// Extra files in `features/auth/auth_impl`, relative to the package.
const _authImpl = <String, String>{
  'lib/src/di/auth_global_module.dart': '''
import 'dart:async';
import 'package:auth_api/auth_api.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:home_api/home_api.dart';
import 'package:injectable/injectable.dart';

GetIt get authGetIt => GetIt.instance;

class LoginRepository {}
class AuthSDKImpl implements AuthSDK {}
class HomeSDKImpl implements HomeSDK {}
class AuthManifest implements FeatureManifest {}
class Port implements AuthTokenPort {}
class AuthPortSDKImpl implements AuthPortSDK {}

class AuthGlobalModule extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    final getIt = GetIt.instance;
    getIt
      ..registerSingleton<AuthSDK>(AuthSDKImpl())
      ..registerSingleton<AuthManifest>(AuthManifest())
      // di-global: the network layer resolves it.
      ..registerLazySingleton<AuthTokenPort>(Port.new)
      ..registerLazySingleton<LoginRepository>(LoginRepository.new)
      ..registerSingleton<HomeSDK>(HomeSDKImpl());
    gh.lazySingleton<LoginRepository>(LoginRepository.new);
    gh.lazySingleton<AuthPortSDK>(AuthPortSDKImpl.new);
    getIt.registerSingleton(Port()); // di-global: inferred type, same line
    // A trailing annotation above does not cover this line.
    getIt.registerSingleton<LoginRepository>(LoginRepository());
    // Nor does an empty reason.
    getIt.registerSingleton<Object>(Object()); // di-global:
  }

  void notInit() => GetIt.I.registerSingleton<LoginRepository>(LoginRepository());
}

class NotAModule {
  FutureOr<void> init(GetItHelper gh) =>
      GetIt.I.registerSingleton<LoginRepository>(LoginRepository());
}
''',
  'lib/src/presentation/login_page.dart': '''
import 'dart:async';
import 'package:auth_api/auth_api.dart';
import 'package:auth_impl/src/di/auth_global_module.dart';
import 'package:injectable/injectable.dart';

/// Resolves [GetIt] and [authGetIt] in a doc comment: not a use.
class LoginPage {
  LoginPage(this.sdk);

  final AuthSDK sdk;

  void build() {
    GetIt.I<AuthSDK>();
    GetIt.instance.get<AuthSDK>();
    authGetIt<LoginRepository>();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<AuthSDK>()) getIt<AuthSDK>();
    final read = getIt.get<AuthSDK>;
    read();
  }
}

class LateModule extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) => GetIt.I<AuthSDK>();
}
''',
  'lib/src/auth_manifest.dart': '''
import 'package:auth_api/auth_api.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:injectable/injectable.dart';

class AuthManifest extends FeatureManifest {
  AuthManifest({required this.sdk}) : flag = GetIt.I.isRegistered<AuthSDK>() {
    GetIt.instance<AuthSDK>();
  }

  final AuthSDK Function() sdk;
  final bool flag;
  final eager = GetIt.I<AuthSDK>();
  late final lazy = GetIt.I<AuthSDK>();
  static final shared = GetIt.I<AuthSDK>();

  bool get isEnabled => GetIt.I.isRegistered<AuthSDK>();

  void registerRoutes(Object registry) {
    GetIt.I<AuthSDK>();
    final provide = () => GetIt.I<AuthSDK>();
    provide();
  }

  Future<void> initialize() async => GetIt.I<AuthSDK>();
}

class const PrimaryManifest() extends FeatureManifest {
  this {
    GetIt.I<AuthSDK>();
  }
}

class NotAManifest {
  NotAManifest() {
    GetIt.I<AuthSDK>();
  }

  bool get isEnabled => GetIt.I.isRegistered<AuthSDK>();
}
''',
  'test/login_page_test.dart': '''
import 'package:auth_api/auth_api.dart';
import 'package:injectable/injectable.dart';
void main() => GetIt.I<AuthSDK>();
''',
};

void main() {
  late _Fixture fixture;

  setUpAll(() => fixture = _Fixture());

  group('no_service_locator_outside_di', () {
    final rule = NoServiceLocatorOutsideDiRule();

    test('flags every GetIt use in feature presentation code', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/lib/src/presentation/login_page.dart',
        ),
        [
          'GetIt.I',
          'GetIt.instance',
          'authGetIt',
          'GetIt.instance',
          'getIt',
          'getIt',
          'getIt',
        ],
      );
    });

    test('ignores DI files', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/lib/src/di/auth_global_module.dart',
        ),
        isEmpty,
      );
    });

    test('ignores tests and other layers', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/test/login_page_test.dart',
        ),
        isEmpty,
      );
      expect(await fixture.lint(rule, 'shared/core/lib/core.dart'), isEmpty);
    });
  });

  group('no_service_locator_in_manifest', () {
    final rule = NoServiceLocatorInManifestRule();

    test('flags GetIt in a manifest constructor, eager field, isEnabled and '
        'registerRoutes, not in closures or other members', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/lib/src/auth_manifest.dart',
        ),
        [
          'GetIt.I',
          'GetIt.instance',
          'GetIt.I',
          'GetIt.I',
          'GetIt.I',
          'GetIt.I',
        ],
      );
    });

    test('ignores other layers', () async {
      expect(await fixture.lint(rule, 'shared/core/lib/core.dart'), isEmpty);
    });
  });

  group('feature_global_module_allowlist', () {
    final rule = FeatureGlobalModuleAllowlistRule();

    test('flags internals and other features, allows the own eager or lazy '
        'SDK, a manifest and annotated lines', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/lib/src/di/auth_global_module.dart',
        ),
        [
          'registerLazySingleton: LoginRepository',
          'registerSingleton: HomeSDK',
          'lazySingleton: LoginRepository',
          'registerSingleton: LoginRepository',
          'registerSingleton: Object',
        ],
      );
    });

    test('ignores registrations outside a feature module', () async {
      expect(
        await fixture.lint(
          rule,
          'features/auth/auth_impl/lib/src/presentation/login_page.dart',
        ),
        isEmpty,
      );
    });
  });
}

/// Resolves the in-memory workspace and runs a rule over one library.
class _Fixture() {
  final root = '${Directory.current.path}/.dart_tool/di_rules_fixture';
  late final provider = OverlayResourceProvider(
    PhysicalResourceProvider.INSTANCE,
  );
  late final AnalysisContextCollection collection = () {
    final ws = '$root/ws';
    final packages = <Map<String, String>>[];

    void write(String path, String content) =>
        provider.setOverlay(path, content: content, modificationStamp: 0);

    void addPackage(String name, String dir, String source) {
      packages.add({
        'name': name,
        'rootUri': Uri.directory(dir).toString(),
        'packageUri': 'lib/',
      });
      write('$dir/pubspec.yaml', 'name: $name\nresolution: workspace\n');
      write('$dir/lib/$name.dart', source);
    }

    _workspace.forEach(
      (path, source) => addPackage(path.split('/').last, '$ws/$path', source),
    );
    _authImpl.forEach(
      (path, source) => write('$ws/features/auth/auth_impl/$path', source),
    );
    _pub.forEach(
      (name, source) => addPackage(name, '$root/pub_cache/$name-1.0.0', source),
    );

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

  /// What [rule] flags in the library at [path]: the flagged source, or
  /// `<source>: <registered type>` for the allowlist rule.
  Future<List<String>> lint(AnalysisRule rule, String path) async {
    final filePath = '$root/ws/$path';
    final result =
        await collection
                .contextFor(filePath)
                .currentSession
                .getResolvedUnit(filePath)
            as ResolvedUnitResult;

    final listener = RecordingDiagnosticListener();
    final reporter = DiagnosticReporter(
      listener,
      result.libraryElement.firstFragment.source,
    );
    final registry = RuleVisitorRegistryImpl(enableTiming: false);
    rule
      ..reporter = reporter
      ..registerNodeProcessors(
        registry,
        _RuleContext(
          RuleContextUnit(
            file: provider.getFile(filePath),
            content: result.content,
            diagnosticReporter: reporter,
            unit: result.unit,
          ),
          result.libraryElement,
        ),
      );
    result.unit.accept(
      AnalysisRuleVisitor(registry, shouldPropagateExceptions: true),
    );
    return [
      for (final d in listener.diagnostics)
        [
          result.content.substring(d.offset, d.offset + d.length),
          ?RegExp("^'(.+?)'").firstMatch(d.message)?[1],
        ].join(': '),
    ];
  }
}

class _RuleContext(
  @override final RuleContextUnit definingUnit,
  @override final LibraryElement? libraryElement,
) implements RuleContext {
  @override
  RuleContextUnit? get currentUnit => definingUnit;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
