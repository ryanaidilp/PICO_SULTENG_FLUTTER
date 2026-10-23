import 'dart:io';

import 'package:host_registry_generator/host_registry_generator.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:test/test.dart';

/// Writes a minimal package under `<root>/<relativeDir>` with an optional
/// `archipelago: di_modules:` block and an optional `dependencies:` list
/// appended verbatim. [dependsOn] only needs dependency *names* — the
/// dependency-closure walk (`HostRegistryService.dependencyClosure`) reads
/// `dependencies:` map keys, never resolves `path:`, so a fake `any`
/// constraint is enough for a synthetic workspace.
void _writePackage(
  Directory root, {
  required String relativeDir,
  required String name,
  String? archipelagoYaml,
  List<String> dependsOn = const [],
}) {
  final dir = Directory(p.join(root.path, relativeDir))
    ..createSync(recursive: true);
  final buffer = StringBuffer()
    ..writeln('name: $name')
    ..writeln('version: 0.1.0')
    ..writeln('environment:')
    ..writeln('  sdk: ">=3.0.0 <4.0.0"');
  if (dependsOn.isNotEmpty) {
    buffer.writeln('dependencies:');
    for (final dep in dependsOn) {
      buffer.writeln('  $dep: any');
    }
  }
  if (archipelagoYaml != null) buffer.writeln(archipelagoYaml);
  File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync(buffer.toString());
}

/// (Re)writes `apps/my_app/pubspec.yaml` so `HostRegistryService.generate`
/// can resolve the app package and compute its dependency closure. Defaults
/// to no dependencies — tests that need `generate` to pick up a package's
/// `di_modules` must pass its name in [dependsOn].
void _writeAppPubspec(Directory root, {List<String> dependsOn = const []}) {
  _writePackage(
    root,
    relativeDir: 'apps/my_app',
    name: 'my_app',
    dependsOn: dependsOn,
  );
}

const _injectorTemplate = r'''
import 'package:dependencies/di.dart';

// archipelago:feature_imports:start
// archipelago:feature_imports:end

@InjectableInit(
  externalPackageModulesBefore: [
    // archipelago:feature_modules_before:start
    // archipelago:feature_modules_before:end
  ],
  externalPackageModulesAfter: [
    // archipelago:feature_modules_after:start
    // archipelago:feature_modules_after:end
  ],
)
Future<void> initializeInjector() => \$initGetIt(getIt);
''';

void main() {
  late Directory tmpDir;
  late String injectorPath;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('host_registry_service_test_');
    // Root pubspec.yaml, skipped by PackageScanner.
    File(p.join(tmpDir.path, 'pubspec.yaml'))
        .writeAsStringSync('name: root_workspace\nworkspace:\n  - apps/*\n');

    final appDir = Directory(p.join(tmpDir.path, 'apps', 'my_app', 'lib', 'di'))
      ..createSync(recursive: true);
    injectorPath = p.join(appDir.path, 'injector.dart');
    File(injectorPath).writeAsStringSync(_injectorTemplate);
    // Minimal app package so `generate` can resolve the app and compute its
    // dependency closure. Tests that need a specific package's di_modules
    // picked up call `_writeAppPubspec` again with `dependsOn`.
    _writeAppPubspec(tmpDir);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('HostRegistryService.scanManifests', () {
    test('leaf packages with no archipelago key contribute nothing', () {
      _writePackage(tmpDir, relativeDir: 'packages/leaf', name: 'leaf');
      final service = HostRegistryService(rootPath: tmpDir.path);
      final manifests = service.scanManifests();
      expect(manifests.every((m) => m.diModules.isEmpty), isTrue);
    });

    test('collects declared di_modules across packages', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );
      final service = HostRegistryService(rootPath: tmpDir.path);
      final manifests = service.scanManifests();
      final withModules = manifests.where((m) => m.diModules.isNotEmpty);
      expect(withModules, hasLength(1));
      expect(withModules.single.packageName, 'app_utilities');
    });
  });

  group('HostRegistryService.generate', () {
    test('emits sorted, deduplicated imports and ordered modules', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );
      _writePackage(
        tmpDir,
        relativeDir: 'features/auth',
        name: 'auth_impl',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AuthImplGlobalModule
      depends_on: [app_utilities]
''',
      );

      _writeAppPubspec(tmpDir, dependsOn: ['app_utilities', 'auth_impl']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      final result = service.generate(targetInjectorPath: injectorPath);

      expect(result.packagesWithModules, 2);
      expect(result.totalModulesDeclared, 2);
      expect(result.changed, isTrue);

      final content = File(injectorPath).readAsStringSync();
      expect(
        content,
        contains(
          "import 'package:app_utilities/app_utilities.dart';\n"
          "import 'package:auth_impl/auth_impl.dart';",
        ),
      );
      expect(
        content,
        contains(
          'ExternalModule(AppUtilitiesPackageModule),\n'
          '    ExternalModule(AuthImplGlobalModule),',
        ),
      );
    });

    test('splits before/after scope into their respective marker regions', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );
      _writePackage(
        tmpDir,
        relativeDir: 'features/push',
        name: 'push_notification_impl',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: PushNotificationGlobalModule
      scope: after
''',
      );

      _writeAppPubspec(
        tmpDir,
        dependsOn: ['app_utilities', 'push_notification_impl'],
      );
      final service = HostRegistryService(rootPath: tmpDir.path);
      service.generate(targetInjectorPath: injectorPath);
      final content = File(injectorPath).readAsStringSync();

      final beforeBlock = MarkerScanner.scanBlocks(content)
          .firstWhere((b) => b.slot == 'feature_modules_before');
      final afterBlock = MarkerScanner.scanBlocks(content)
          .firstWhere((b) => b.slot == 'feature_modules_after');
      final lines = content.split('\n');

      expect(
        beforeBlock.innerLines(lines).join('\n'),
        contains('AppUtilitiesPackageModule'),
      );
      expect(
        beforeBlock.innerLines(lines).join('\n'),
        isNot(contains('PushNotificationGlobalModule')),
      );
      expect(
        afterBlock.innerLines(lines).join('\n'),
        contains('PushNotificationGlobalModule'),
      );
    });

    test(
      'is idempotent — running generate twice produces no further change',
      () {
        _writePackage(
          tmpDir,
          relativeDir: 'utilities/app_utilities',
          name: 'app_utilities',
          archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
        );

        _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);
        final service = HostRegistryService(rootPath: tmpDir.path);
        final first = service.generate(targetInjectorPath: injectorPath);
        expect(first.changed, isTrue);

        final afterFirstRun = File(injectorPath).readAsStringSync();
        final second = service.generate(targetInjectorPath: injectorPath);
        final afterSecondRun = File(injectorPath).readAsStringSync();

        expect(second.changed, isFalse);
        expect(afterSecondRun, afterFirstRun);
      },
    );

    test('normalizes a hand-edited marker region to the canonical form', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );

      // Simulate a stale/hand-edited file: markers present, but with
      // different (stale) content already inside them.
      final stale = _injectorTemplate.replaceFirst(
        '// archipelago:feature_imports:start\n// archipelago:feature_imports:end',
        '// archipelago:feature_imports:start\n'
            "import 'package:some_removed_pkg/some_removed_pkg.dart';\n"
            '// archipelago:feature_imports:end',
      );
      File(injectorPath).writeAsStringSync(stale);

      _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      service.generate(targetInjectorPath: injectorPath);
      final content = File(injectorPath).readAsStringSync();

      expect(content, isNot(contains('some_removed_pkg')));
      expect(
        content,
        contains("import 'package:app_utilities/app_utilities.dart';"),
      );
    });

    test('propagates a named cycle error from the resolver', () {
      _writePackage(
        tmpDir,
        relativeDir: 'features/a',
        name: 'a',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AModule
      depends_on: [b]
''',
      );
      _writePackage(
        tmpDir,
        relativeDir: 'features/b',
        name: 'b',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: BModule
      depends_on: [a]
''',
      );

      _writeAppPubspec(tmpDir, dependsOn: ['a', 'b']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      expect(
        () => service.generate(targetInjectorPath: injectorPath),
        throwsA(isA<DiModuleCycleException>()),
      );
    });

    test('throws when the target file does not exist', () {
      final service = HostRegistryService(rootPath: tmpDir.path);
      expect(
        () => service.generate(
          targetInjectorPath: p.join(tmpDir.path, 'does_not_exist.dart'),
        ),
        throwsA(isA<HostRegistryTargetNotFoundException>()),
      );
    });

    test(
      'throws when a required marker pair is missing entirely from the file',
      () {
        File(injectorPath)
            .writeAsStringSync("import 'package:foo/foo.dart';\n");
        final service = HostRegistryService(rootPath: tmpDir.path);
        expect(
          () => service.generate(targetInjectorPath: injectorPath),
          throwsA(isA<MarkerImbalanceException>()),
        );
      },
    );

    test('throws HostRegistryAppNotFoundException when the app has no '
        'pubspec.yaml', () {
      File(p.join(tmpDir.path, 'apps', 'my_app', 'pubspec.yaml')).deleteSync();
      final service = HostRegistryService(rootPath: tmpDir.path);
      expect(
        () => service.generate(targetInjectorPath: injectorPath),
        throwsA(isA<HostRegistryAppNotFoundException>()),
      );
    });

    test('never emits a package the app does not transitively depend on', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );
      // Declares di_modules but the app never depends on it — this is
      // the network_sdk_http-in-template_app bug from Archipelago-72z8.32.
      _writePackage(
        tmpDir,
        relativeDir: 'infrastructure/unused_sdk',
        name: 'unused_sdk',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: UnusedSdkPackageModule
''',
      );

      _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      final result = service.generate(targetInjectorPath: injectorPath);

      expect(result.packagesWithModules, 1);
      final content = File(injectorPath).readAsStringSync();
      expect(content, contains('AppUtilitiesPackageModule'));
      expect(content, isNot(contains('UnusedSdkPackageModule')));
      expect(content, isNot(contains('unused_sdk')));
    });

    test("follows transitive dependencies, not just the app's direct ones", () {
      // app depends on `mid` only; `mid` depends on `leaf`, which
      // declares a di_modules entry. It must still be picked up.
      _writePackage(
        tmpDir,
        relativeDir: 'features/leaf',
        name: 'leaf',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: LeafPackageModule
''',
      );
      _writePackage(
        tmpDir,
        relativeDir: 'features/mid',
        name: 'mid',
        dependsOn: ['leaf'],
      );

      _writeAppPubspec(tmpDir, dependsOn: ['mid']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      final result = service.generate(targetInjectorPath: injectorPath);

      expect(result.packagesWithModules, 1);
      final content = File(injectorPath).readAsStringSync();
      expect(content, contains('LeafPackageModule'));
    });

    test('throws DiModuleCrossPackageDuplicateException when two packages in '
        "the app's closure declare the same class", () {
      _writePackage(
        tmpDir,
        relativeDir: 'features/impl',
        name: 'feature_impl',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: FeatureGlobalModule
''',
      );
      _writePackage(
        tmpDir,
        relativeDir: 'features/noop',
        name: 'feature_noop',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: FeatureGlobalModule
''',
      );

      _writeAppPubspec(tmpDir, dependsOn: ['feature_impl', 'feature_noop']);
      final service = HostRegistryService(rootPath: tmpDir.path);
      expect(
        () => service.generate(targetInjectorPath: injectorPath),
        throwsA(isA<DiModuleCrossPackageDuplicateException>()),
      );
    });

    test(
      'keeps a blank line before the imports :end marker, as dart format does',
      () {
        _writePackage(
          tmpDir,
          relativeDir: 'utilities/app_utilities',
          name: 'app_utilities',
          archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
        );
        _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);

        HostRegistryService(rootPath: tmpDir.path)
            .generate(targetInjectorPath: injectorPath);

        expect(
          File(injectorPath).readAsStringSync(),
          contains(
            "app_utilities.dart';\n\n// archipelago:feature_imports:end",
          ),
        );
      },
    );

    group('modules no manifest declares', () {
      void seed() {
        _writePackage(
          tmpDir,
          relativeDir: 'utilities/app_utilities',
          name: 'app_utilities',
          archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
        );
        _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);
        File(injectorPath).writeAsStringSync(
          _injectorTemplate
              .replaceFirst(
                '// archipelago:feature_imports:start\n',
                '// archipelago:feature_imports:start\n'
                    "import 'package:manual_pkg/manual_pkg.dart';\n",
              )
              .replaceFirst(
                '  // archipelago:feature_modules_before:start\n',
                '  // archipelago:feature_modules_before:start\n'
                    '    ExternalModule(ManualModule),\n',
              ),
        );
      }

      test('are kept after the resolved ones and reported', () {
        seed();
        final result = HostRegistryService(rootPath: tmpDir.path)
            .generate(targetInjectorPath: injectorPath);

        expect(result.preservedModules, ['ManualModule']);
        final content = File(injectorPath).readAsStringSync();
        expect(
          content,
          contains(
            'ExternalModule(AppUtilitiesPackageModule),\n'
            '    ExternalModule(ManualModule),',
          ),
        );
        expect(
          content,
          contains("import 'package:manual_pkg/manual_pkg.dart';"),
        );
      });

      test('a commented-out entry is kept as a comment, not revived', () {
        seed();
        File(injectorPath).writeAsStringSync(
          File(injectorPath)
              .readAsStringSync()
              .replaceFirst(
                '    ExternalModule(ManualModule),\n',
                '    ExternalModule(ManualModule),\n'
                    '    ExternalModule(ManualModule),\n'
                    '    // ExternalModule(OldModule),\n',
              )
              .replaceFirst(
                '// archipelago:feature_imports:start\n',
                '// archipelago:feature_imports:start\n'
                    "// import 'package:old/old.dart';\n",
              ),
        );

        final result = HostRegistryService(rootPath: tmpDir.path)
            .generate(targetInjectorPath: injectorPath);

        expect(result.preservedModules, ['ManualModule']);
        final content = File(injectorPath).readAsStringSync();
        expect(
          'ExternalModule(ManualModule)'.allMatches(content),
          hasLength(1),
        );
        expect(
          RegExp(
            r'^\s*ExternalModule\(OldModule\)',
            multiLine: true,
          ).hasMatch(content),
          isFalse,
        );
        expect(
          '// ExternalModule(OldModule),'.allMatches(content),
          hasLength(1),
        );
        expect(
          "// import 'package:old/old.dart';".allMatches(content),
          hasLength(1),
        );

        HostRegistryService(rootPath: tmpDir.path)
            .generate(targetInjectorPath: injectorPath);
        expect(File(injectorPath).readAsStringSync(), content);
      });

      test('are dropped with prune: true', () {
        seed();
        HostRegistryService(rootPath: tmpDir.path)
            .generate(targetInjectorPath: injectorPath, prune: true);

        expect(
          File(injectorPath).readAsStringSync(),
          isNot(contains('Manual')),
        );
      });
    });

    test('--check semantics: write: false leaves the file untouched', () {
      _writePackage(
        tmpDir,
        relativeDir: 'utilities/app_utilities',
        name: 'app_utilities',
        archipelagoYaml: '''
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''',
      );
      _writeAppPubspec(tmpDir, dependsOn: ['app_utilities']);

      final service = HostRegistryService(rootPath: tmpDir.path);
      final before = File(injectorPath).readAsStringSync();
      final result = service.generate(
        targetInjectorPath: injectorPath,
        write: false,
      );

      expect(result.changed, isTrue);
      expect(File(injectorPath).readAsStringSync(), before);
    });
  });

  group('HostRegistryService.generateTestHarness', () {
    late String harnessPath;

    setUp(() {
      harnessPath = p.join(
        tmpDir.path,
        'apps',
        'my_app',
        testHarnessRelativePath,
      );
    });

    void declare(String name, {String dependsOn = '[]'}) => _writePackage(
      tmpDir,
      relativeDir: 'packages/$name',
      name: name,
      archipelagoYaml:
          '''
archipelago:
  test_prerequisites:
    - class: ${name}Prereq
      reason: >-
        $name does platform I/O during DI init.
      depends_on: $dependsOn
''',
    );

    List<String> entries() => [
      for (final line in File(harnessPath).readAsLinesSync())
        if (line.trim().startsWith('await ')) line.trim(),
    ];

    test('creates the skeleton and lists every declaring package in resolved '
        'order', () {
      ['d', 'c', 'b'].forEach(declare);
      declare('a', dependsOn: '[d]');
      _writePackage(tmpDir, relativeDir: 'packages/plain', name: 'plain');
      _writeAppPubspec(tmpDir, dependsOn: ['a', 'b', 'c', 'd', 'plain']);

      final result = HostRegistryService(rootPath: tmpDir.path)
          .generateTestHarness(targetHarnessPath: harnessPath);

      expect(result.changed, isTrue);
      expect(result.prerequisites, hasLength(4));
      expect(entries(), [
        'await bPrereq().install();',
        'await cPrereq().install();',
        'await dPrereq().install();',
        'await aPrereq().install();',
      ]);
      final content = File(harnessPath).readAsStringSync();
      expect(
        content,
        contains(
          "import 'package:a/testing.dart';\n"
          "import 'package:b/testing.dart';\n"
          "import 'package:c/testing.dart';\n"
          "import 'package:d/testing.dart';\n"
          '\n'
          '// archipelago:test_prerequisite_imports:end',
        ),
      );
      expect(
        content,
        contains(
          '  await dPrereq().install();\n'
          '\n'
          '  /// a does platform I/O during DI init.\n'
          '  await aPrereq().install();\n'
          '  // archipelago:test_prerequisites:end',
        ),
      );
      expect(content, contains('installCompositionRootPrerequisites()'));
    });

    test('is byte-idempotent', () {
      declare('a');
      _writeAppPubspec(tmpDir, dependsOn: ['a']);
      final service = HostRegistryService(rootPath: tmpDir.path);

      service.generateTestHarness(targetHarnessPath: harnessPath);
      final first = File(harnessPath).readAsStringSync();
      final second = service.generateTestHarness(
        targetHarnessPath: harnessPath,
      );

      expect(second.changed, isFalse);
      expect(File(harnessPath).readAsStringSync(), first);
    });

    test('removing a declaration removes its entry and its import', () {
      declare('a');
      declare('b');
      _writeAppPubspec(tmpDir, dependsOn: ['a', 'b']);
      final service = HostRegistryService(rootPath: tmpDir.path)
        ..generateTestHarness(targetHarnessPath: harnessPath);

      _writePackage(tmpDir, relativeDir: 'packages/b', name: 'b');
      service.generateTestHarness(targetHarnessPath: harnessPath);

      final content = File(harnessPath).readAsStringSync();
      expect(entries(), ['await aPrereq().install();']);
      expect(content, isNot(contains('package:b/')));
    });

    test('keeps hand-written code outside the markers', () {
      declare('a');
      _writeAppPubspec(tmpDir, dependsOn: ['a']);
      File(harnessPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          testHarnessSkeleton.replaceFirst(
            '  // archipelago:test_prerequisites:end\n',
            '  // archipelago:test_prerequisites:end\n  handWritten();\n',
          ),
        );

      HostRegistryService(rootPath: tmpDir.path)
          .generateTestHarness(targetHarnessPath: harnessPath);

      final content = File(harnessPath).readAsStringSync();
      expect(content, contains('  handWritten();'));
      expect(entries(), ['await aPrereq().install();']);
    });

    test('ignores packages outside the app dependency closure', () {
      declare('a');
      declare('unused');
      _writeAppPubspec(tmpDir, dependsOn: ['a']);

      HostRegistryService(rootPath: tmpDir.path)
          .generateTestHarness(targetHarnessPath: harnessPath);

      expect(entries(), ['await aPrereq().install();']);
    });

    test('wraps a long reason to fit 80 columns', () {
      _writePackage(
        tmpDir,
        relativeDir: 'packages/a',
        name: 'a',
        archipelagoYaml:
            '''
archipelago:
  test_prerequisites:
    - class: APrereq
      reason: >-
        ${List.filled(30, 'word').join(' ')}
''',
      );
      _writeAppPubspec(tmpDir, dependsOn: ['a']);

      HostRegistryService(rootPath: tmpDir.path)
          .generateTestHarness(targetHarnessPath: harnessPath);

      final lines = File(harnessPath).readAsLinesSync();
      expect(lines.where((l) => l.trim().startsWith('/// word')).length, 2);
      expect(lines.every((l) => l.length <= 80), isTrue);
    });

    test('write: false reports drift without creating the file', () {
      declare('a');
      _writeAppPubspec(tmpDir, dependsOn: ['a']);

      final result = HostRegistryService(rootPath: tmpDir.path)
          .generateTestHarness(targetHarnessPath: harnessPath, write: false);

      expect(result.changed, isTrue);
      expect(File(harnessPath).existsSync(), isFalse);
    });

    test('propagates a cycle from the resolver', () {
      declare('a', dependsOn: '[b]');
      declare('b', dependsOn: '[a]');
      _writeAppPubspec(tmpDir, dependsOn: ['a', 'b']);

      expect(
        () =>
            HostRegistryService(rootPath: tmpDir.path)
                .generateTestHarness(targetHarnessPath: harnessPath),
        throwsA(isA<DiModuleCycleException>()),
      );
    });

    test('throws when an existing harness lacks a marker pair', () {
      File(harnessPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '// archipelago:test_prerequisites:start\n'
          '// archipelago:test_prerequisites:end\n',
        );

      expect(
        () =>
            HostRegistryService(rootPath: tmpDir.path)
                .generateTestHarness(targetHarnessPath: harnessPath),
        throwsA(isA<MarkerImbalanceException>()),
      );
    });

    test('throws when the app has no injector.dart', () {
      File(injectorPath).deleteSync();

      expect(
        () =>
            HostRegistryService(rootPath: tmpDir.path)
                .generateTestHarness(targetHarnessPath: harnessPath),
        throwsA(isA<HostRegistryTargetNotFoundException>()),
      );
    });
  });

  group('HostRegistryService.dependencyClosure', () {
    test('includes the app itself and its transitive dependencies', () {
      final packages = [
        const PackageInfo(
          name: 'app',
          path: '/app',
          version: '0.1.0',
          dependencies: ['mid'],
          devDependencies: [],
          isFlutter: false,
          hasTests: false,
        ),
        const PackageInfo(
          name: 'mid',
          path: '/mid',
          version: '0.1.0',
          dependencies: ['leaf'],
          devDependencies: [],
          isFlutter: false,
          hasTests: false,
        ),
        const PackageInfo(
          name: 'leaf',
          path: '/leaf',
          version: '0.1.0',
          dependencies: [],
          devDependencies: [],
          isFlutter: false,
          hasTests: false,
        ),
        const PackageInfo(
          name: 'unrelated',
          path: '/unrelated',
          version: '0.1.0',
          dependencies: [],
          devDependencies: [],
          isFlutter: false,
          hasTests: false,
        ),
      ];

      final closure = HostRegistryService.dependencyClosure('app', packages);

      expect(closure, {'app', 'mid', 'leaf'});
      expect(closure, isNot(contains('unrelated')));
    });

    test('ignores external pub dependencies with no matching package', () {
      final packages = [
        const PackageInfo(
          name: 'app',
          path: '/app',
          version: '0.1.0',
          dependencies: ['get_it'],
          devDependencies: [],
          isFlutter: false,
          hasTests: false,
        ),
      ];

      final closure = HostRegistryService.dependencyClosure('app', packages);

      expect(closure, {'app'});
    });
  });
}
