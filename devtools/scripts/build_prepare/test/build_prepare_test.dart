import 'dart:io';

import 'package:build_prepare/src/build_prepare_command.dart';
import 'package:build_prepare/src/build_prepare_config.dart';
import 'package:build_prepare/src/build_prepare_runner.dart';
import 'package:build_prepare/src/build_prepare_state.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('BuildPrepareConfig', () {
    test('parses valid YAML config', () {
      const yaml = '''
build_prepare:
  mappings:
    - debug: monitoring_impl
      release: monitoring_noop
    - debug: app_debugger
      release: app_debugger_noop
  target_paths:
    - apps/template_app
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);

      expect(config, isNotNull);
      expect(config!.mappings, hasLength(2));
      expect(config.mappings[0].debug, equals('monitoring_impl'));
      expect(config.mappings[0].release, equals('monitoring_noop'));
      expect(config.mappings[1].debug, equals('app_debugger'));
      expect(config.mappings[1].release, equals('app_debugger_noop'));
      expect(config.targetPaths, hasLength(1));
      expect(config.targetPaths[0], equals('apps/template_app'));
    });

    test('parses config with optional version constraints', () {
      const yaml = '''
build_prepare:
  mappings:
    - debug: monitoring_impl
      release: monitoring_noop
      debug_version: ^1.0.0
      release_version: ^1.0.0
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);

      expect(config, isNotNull);
      expect(config!.mappings[0].debugVersion, equals('^1.0.0'));
      expect(config.mappings[0].releaseVersion, equals('^1.0.0'));
    });

    test('returns null for empty YAML', () {
      final config = BuildPrepareConfig.fromYamlString('');
      expect(config, isNull);
    });

    test('returns null for YAML without build_prepare key', () {
      const yaml = '''
other_key:
  mappings:
    - debug: something
      release: something_noop
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);
      expect(config, isNull);
    });

    test('skips entries with missing required fields', () {
      const yaml = '''
build_prepare:
  mappings:
    - debug: monitoring_impl
    - debug: app_debugger
      release: app_debugger_noop
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);

      expect(config, isNotNull);
      expect(config!.mappings, hasLength(1));
      expect(config.mappings[0].debug, equals('app_debugger'));
    });

    test('defaults to empty target_paths', () {
      const yaml = '''
build_prepare:
  mappings:
    - debug: monitoring_impl
      release: monitoring_noop
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);

      expect(config, isNotNull);
      expect(config!.targetPaths, isEmpty);
    });

    test('loads from YAML file', () {
      final tempDir = Directory.systemTemp.createTempSync('build_prepare_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final configFile = File(p.join(tempDir.path, 'build_prepare.yaml'));
      configFile.writeAsStringSync('''
build_prepare:
  mappings:
    - debug: monitoring_impl
      release: monitoring_noop
''');

      final config = BuildPrepareConfig.fromYamlFile(configFile.path);
      expect(config, isNotNull);
      expect(config!.mappings, hasLength(1));
    });

    test('returns null for non-existent file', () {
      final config = BuildPrepareConfig.fromYamlFile('/non/existent/path.yaml');
      expect(config, isNull);
    });

    test('parses flavors list when present', () {
      const yaml = '''
build_prepare:
  mappings:
    - debug: app_debugger
      release: app_debugger_noop
      flavors: [production, staging]
    - debug: monitoring_impl
      release: monitoring_noop
''';
      final config = BuildPrepareConfig.fromYamlString(yaml);
      expect(config, isNotNull);
      expect(config!.mappings, hasLength(2));
      expect(config.mappings[0].flavors, ['production', 'staging']);
      expect(config.mappings[1].flavors, isEmpty);
    });
  });

  group('DependencyMapping.appliesToFlavor', () {
    test('returns true when flavor is null (no filter)', () {
      const mapping = DependencyMapping(
        debug: 'd',
        release: 'r',
        flavors: ['production'],
      );
      expect(mapping.appliesToFlavor(null), isTrue);
    });

    test('returns true when flavors is empty (matches everything)', () {
      const mapping = DependencyMapping(debug: 'd', release: 'r');
      expect(mapping.appliesToFlavor('production'), isTrue);
      expect(mapping.appliesToFlavor('staging'), isTrue);
    });

    test('returns true when flavor is in the list', () {
      const mapping = DependencyMapping(
        debug: 'd',
        release: 'r',
        flavors: ['production', 'beta'],
      );
      expect(mapping.appliesToFlavor('production'), isTrue);
      expect(mapping.appliesToFlavor('beta'), isTrue);
    });

    test('returns false when flavor is not in the list', () {
      const mapping = DependencyMapping(
        debug: 'd',
        release: 'r',
        flavors: ['production'],
      );
      expect(mapping.appliesToFlavor('staging'), isFalse);
    });
  });

  group('BuildPrepareCommand.swapDependency', () {
    const samplePubspec = '''
name: template_app
description: The main app.

dependencies:
  flutter:
    sdk: flutter
  monitoring_impl:
    path: ../../infrastructure/monitoring_impl
  app_debugger:
    path: ../../utilities/app_debugger

dev_dependencies:
  test: ^1.0.0
''';

    test('swaps debug dep to release', () {
      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: samplePubspec,
        fromDep: 'monitoring_impl',
        toDep: 'monitoring_noop',
      );

      expect(result, isNotNull);
      expect(result, contains('monitoring_noop:'));
      expect(result, contains('monitoring_noop'));
      expect(result, isNot(contains('monitoring_impl')));
    });

    test('swaps release back to debug', () {
      final released = BuildPrepareCommand.swapDependency(
        pubspecContent: samplePubspec,
        fromDep: 'monitoring_impl',
        toDep: 'monitoring_noop',
      );

      expect(released, isNotNull);

      final debugged = BuildPrepareCommand.swapDependency(
        pubspecContent: released!,
        fromDep: 'monitoring_noop',
        toDep: 'monitoring_impl',
      );

      expect(debugged, isNotNull);
      expect(debugged, contains('monitoring_impl:'));
      expect(debugged, isNot(contains('monitoring_noop')));
    });

    test('returns null when dependency not found', () {
      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: samplePubspec,
        fromDep: 'nonexistent_package',
        toDep: 'replacement_package',
      );

      expect(result, isNull);
    });

    test('does not modify other dependencies', () {
      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: samplePubspec,
        fromDep: 'monitoring_impl',
        toDep: 'monitoring_noop',
      );

      expect(result, isNotNull);
      expect(result, contains('app_debugger:'));
      expect(result, contains('flutter:'));
      expect(result, contains('test: ^1.0.0'));
    });

    test('swaps only the leaf path segment, not parent/group dirs', () {
      const pubspec = '''
name: template_app

dependencies:
  app_blackbox:
    path: ../../features/app_blackbox/app_blackbox
''';

      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: pubspec,
        fromDep: 'app_blackbox',
        toDep: 'app_blackbox_noop',
      );

      expect(result, isNotNull);
      expect(
        result,
        contains('path: ../../features/app_blackbox/app_blackbox_noop'),
      );
      // The GROUP dir must be untouched.
      expect(
        result,
        isNot(contains('features/app_blackbox_noop/app_blackbox_noop')),
      );
    });

    test('prefix-collision: swapping app_debugger leaves siblings intact', () {
      const pubspec = '''
name: template_app

dependencies:
  app_debugger:
    path: ../../features/app_debugger/app_debugger
  app_debugger_network:
    path: ../../features/app_debugger_network/app_debugger_network
  app_debugger_storage:
    path: ../../features/app_debugger_storage/app_debugger_storage
''';

      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: pubspec,
        fromDep: 'app_debugger',
        toDep: 'app_debugger_noop',
      );

      expect(result, isNotNull);
      // app_debugger swapped to app_debugger_noop.
      expect(result, contains('app_debugger_noop:'));
      expect(result, isNot(contains('app_debugger:\n')));
      // Siblings sharing the prefix are completely untouched.
      expect(result, contains('app_debugger_network:'));
      expect(
        result,
        contains('../../features/app_debugger_network/app_debugger_network'),
      );
      expect(result, contains('app_debugger_storage:'));
      expect(
        result,
        contains('../../features/app_debugger_storage/app_debugger_storage'),
      );
      // The corruption the old replaceAll produced must NOT appear.
      expect(result, isNot(contains('app_debugger_noop_network')));
      expect(result, isNot(contains('app_debugger_noop_storage')));
    });

    test(
      'prefix-collision: fromDep that is a path segment of siblings survives '
      'unrelated foo_bar/foo_bar_noop entries',
      () {
        const pubspec = '''
name: template_app

dependencies:
  foo:
    path: ../../features/foo/foo
  foo_bar:
    path: ../../features/foo_bar/foo_bar
  foo_bar_noop:
    path: ../../features/foo_bar/foo_bar_noop
''';

        final result = BuildPrepareCommand.swapDependency(
          pubspecContent: pubspec,
          fromDep: 'foo',
          toDep: 'foo_noop',
        );

        expect(result, isNotNull);
        // Exact-match key + its path both swap correctly, including when the
        // path's directory and package-name segments are both `foo`.
        expect(result, contains('foo_noop:'));
        expect(result, contains('path: ../../features/foo/foo_noop'));
        expect(result, isNot(contains('foo:\n')));
        // Unrelated siblings sharing the `foo`/`foo_bar` prefix must survive
        // completely unmutated.
        expect(result, contains('foo_bar:'));
        expect(result, contains('path: ../../features/foo_bar/foo_bar'));
        expect(result, contains('foo_bar_noop:'));
        expect(result, contains('path: ../../features/foo_bar/foo_bar_noop'));
        // The corruption a naive whole-file replaceAll would produce must
        // NOT appear.
        expect(result, isNot(contains('foo_noop_bar')));
        expect(result, isNot(contains('foo_noop_bar_noop')));
        expect(result, isNot(contains('foo_bar_noop_noop')));
      },
    );

    test('mixed state: toDep already present → fromDep removed, no dup', () {
      const pubspec = '''
name: template_app

dependencies:
  app_debugger:
    path: ../../features/app_debugger/app_debugger
  app_debugger_noop:
    path: ../../features/app_debugger/app_debugger_noop
''';

      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: pubspec,
        fromDep: 'app_debugger',
        toDep: 'app_debugger_noop',
      );

      expect(result, isNotNull);
      // fromDep dropped.
      expect(result, isNot(contains('app_debugger:\n')));
      // toDep kept exactly once — must still parse without duplicate keys.
      expect(loadYaml(result!), isA<YamlMap>());
      final deps = (loadYaml(result) as YamlMap)['dependencies'] as YamlMap;
      expect(deps.containsKey('app_debugger'), isFalse);
      expect(deps.containsKey('app_debugger_noop'), isTrue);
    });

    test('fromDep absent → returns null (no-op)', () {
      const pubspec = '''
name: template_app

dependencies:
  app_debugger_noop:
    path: ../../features/app_debugger/app_debugger_noop
''';

      // app_debugger is not present (already swapped) → idempotent no-op.
      final result = BuildPrepareCommand.swapDependency(
        pubspecContent: pubspec,
        fromDep: 'app_debugger',
        toDep: 'app_debugger_noop',
      );

      expect(result, isNull);
    });

    test('full round-trip release→debug restores the impls', () {
      const debugPubspec = '''
name: template_app

dependencies:
  app_debugger:
    path: ../../features/app_debugger/app_debugger
  app_debugger_network:
    path: ../../features/app_debugger_network/app_debugger_network
''';

      // release: app_debugger -> app_debugger_noop
      var content = BuildPrepareCommand.swapDependency(
        pubspecContent: debugPubspec,
        fromDep: 'app_debugger',
        toDep: 'app_debugger_noop',
      )!;
      content =
          BuildPrepareCommand.swapDependency(
            pubspecContent: content,
            fromDep: 'app_debugger_network',
            toDep: 'app_debugger_network_noop',
          ) ??
          content;

      expect(content, contains('app_debugger_noop:'));
      expect(content, contains('app_debugger_network_noop:'));

      // debug: swap back.
      content = BuildPrepareCommand.swapDependency(
        pubspecContent: content,
        fromDep: 'app_debugger_noop',
        toDep: 'app_debugger',
      )!;
      content = BuildPrepareCommand.swapDependency(
        pubspecContent: content,
        fromDep: 'app_debugger_network_noop',
        toDep: 'app_debugger_network',
      )!;

      final deps = (loadYaml(content) as YamlMap)['dependencies'] as YamlMap;
      expect(deps.containsKey('app_debugger'), isTrue);
      expect(deps.containsKey('app_debugger_network'), isTrue);
      expect(deps.containsKey('app_debugger_noop'), isFalse);
      final appDebugger = deps['app_debugger'] as YamlMap;
      expect(appDebugger['path'], '../../features/app_debugger/app_debugger');
    });
  });

  group('BuildPrepareCommand.rewriteDartImports', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dart_import_rewrite_');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    File createDartFile(String relativePath, String content) {
      final file = File(p.join(tempDir.path, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      return file;
    }

    test('rewrites package import prefix in lib/ dart files', () {
      createDartFile('lib/main.dart', '''
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:flutter/material.dart';

void main() {}
''');

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      expect(results, hasLength(1));
      final content = File(p.join(tempDir.path, 'lib/main.dart'))
          .readAsStringSync();
      expect(
        content,
        contains(
          "import 'package:app_launch_tracker_noop/app_launch_tracker_noop.dart'",
        ),
      );
      expect(content, isNot(contains('app_launch_tracker_impl')));
    });

    test('leaves the generated app.dart overlay builder intact '
        '(Archipelago-gmdy.8)', () {
      const appDart = '''
import 'package:app_debugger_api/app_debugger_api.dart';
import 'package:dependencies/di.dart';

    // archipelago:app_builder:start
    builder: (context, child) => GetIt.instance<AppDebuggerSDK>().overlay(
      child: child ?? const SizedBox.shrink(),
    ),
    // archipelago:app_builder:end
''';
      final file = createDartFile('lib/app.dart', appDart);

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_debugger',
        toDep: 'app_debugger_noop',
        rootPath: tempDir.path,
      );

      expect(results, isEmpty);
      expect(file.readAsStringSync(), appDart);
    });

    test('rewrites barrel file suffix', () {
      createDartFile('lib/src/feature.dart', '''
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';

class Feature {}
''');

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      expect(results, hasLength(1));
      final content = File(p.join(tempDir.path, 'lib/src/feature.dart'))
          .readAsStringSync();
      expect(
        content,
        contains(
          'package:app_launch_tracker_noop/app_launch_tracker_noop.dart',
        ),
      );
    });

    test('rewrites in test/ dart files', () {
      createDartFile('test/feature_test.dart', '''
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:test/test.dart';

void main() {}
''');

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      expect(results, hasLength(1));
    });

    test('returns empty list when package name not present', () {
      createDartFile('lib/main.dart', '''
import 'package:flutter/material.dart';
import 'package:monitoring_impl/monitoring_impl.dart';

void main() {}
''');

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      expect(results, isEmpty);
    });

    test('does not modify unrelated imports', () {
      createDartFile('lib/main.dart', '''
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:monitoring_impl/monitoring_impl.dart';
import 'package:flutter/material.dart';

void main() {}
''');

      BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      final content = File(p.join(tempDir.path, 'lib/main.dart'))
          .readAsStringSync();
      expect(content, contains('package:monitoring_impl/monitoring_impl.dart'));
      expect(content, contains('package:flutter/material.dart'));
    });

    test('round-trip: debug->release->debug produces original content', () {
      const original = '''
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:flutter/material.dart';

void main() {}
''';
      createDartFile('lib/main.dart', original);

      BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      final afterRelease = File(p.join(tempDir.path, 'lib/main.dart'))
          .readAsStringSync();
      expect(afterRelease, isNot(equals(original)));

      BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_noop',
        toDep: 'app_launch_tracker_impl',
        rootPath: tempDir.path,
      );

      final afterDebug = File(p.join(tempDir.path, 'lib/main.dart'))
          .readAsStringSync();
      expect(afterDebug, equals(original));
    });

    test('skips non-dart files', () {
      createDartFile('lib/README.md', '''
package:app_launch_tracker_impl/app_launch_tracker_impl.dart
''');

      final results = BuildPrepareCommand.rewriteDartImports(
        targetDir: tempDir,
        fromDep: 'app_launch_tracker_impl',
        toDep: 'app_launch_tracker_noop',
        rootPath: tempDir.path,
      );

      expect(results, isEmpty);
    });
  });

  group('release -> debug round trip', () {
    const appPubspec = '''
name: app # keep me
dependencies:
  flutter:
    sdk: flutter
  zeta:
    path: ../zeta
  app_debugger: # debug dep
    path: ../../utilities/app_debugger
  alpha:
    path: ../alpha
  app_debugger_noop:
    path: ../../utilities/app_debugger_noop

# trailing comment
dev_dependencies:
  test: ^1.0.0
''';

    late Directory root;
    late Directory previousCwd;
    late File pubspec;

    setUp(() {
      previousCwd = Directory.current;
      root = Directory.systemTemp.createTempSync('build_prepare_roundtrip_');
      File(p.join(root.path, 'pubspec.yaml'))
          .writeAsStringSync('name: ws\nworkspace:\n  - apps/app\n');
      File(p.join(root.path, 'build_prepare.yaml')).writeAsStringSync('''
build_prepare:
  mappings:
    - debug: app_debugger
      release: app_debugger_noop
  target_paths:
    - apps/app
''');
      Directory(p.join(root.path, 'apps/app')).createSync(recursive: true);
      pubspec = File(p.join(root.path, 'apps/app/pubspec.yaml'))
        ..writeAsStringSync(appPubspec);
      Directory.current = root.path;
    });

    tearDown(() {
      Directory.current = previousCwd;
      root.deleteSync(recursive: true);
    });

    test('debug after release restores the original byte-for-byte', () async {
      await BuildPrepareRunner().run(['release']);
      expect(pubspec.readAsStringSync(), isNot(appPubspec));

      await BuildPrepareRunner().run(['debug']);
      expect(pubspec.readAsStringSync(), appPubspec);
      expect(BuildPrepareState.exists(root.path), isFalse);

      // Second debug run is a no-op (keeps the noop entry too).
      await BuildPrepareRunner().run(['debug']);
      expect(pubspec.readAsStringSync(), appPubspec);
    });

    test(
      'debug after an edit warns and swaps in place, keeping the edit',
      () async {
        await BuildPrepareRunner().run(['release']);
        final edited = '${pubspec.readAsStringSync()}# edited\n';
        pubspec.writeAsStringSync(edited);

        await BuildPrepareRunner().run(['debug']);

        final after = pubspec.readAsStringSync();
        expect(after, contains('# edited'));
        expect(after, contains('app_debugger:'));
      },
    );
  });

  group('BuildPrepareConfig flavors (ADR-035)', () {
    test('defaults internal_flavors and debug_only', () {
      final config = BuildPrepareConfig.fromYamlString('''
build_prepare:
  mappings: []
''')!;
      expect(config.internalFlavors, [
        'development',
        'staging',
        'alpha',
        'beta',
      ]);
      expect(config.debugOnly, isEmpty);
      expect(config.isInternalFlavor('alpha'), isTrue);
      expect(config.isInternalFlavor('production'), isFalse);
      expect(config.isInternalFlavor('prod_eu'), isFalse);
    });

    test('parses internal_flavors and debug_only', () {
      final config = BuildPrepareConfig.fromYamlString('''
build_prepare:
  internal_flavors: [qa]
  debug_only: [app_blackbox_metrics]
''')!;
      expect(config.internalFlavors, ['qa']);
      expect(config.debugOnly, ['app_blackbox_metrics']);
      expect(config.isInternalFlavor('staging'), isFalse);
    });
  });

  group('flavor-driven swap and leak check (ADR-035)', () {
    const appPubspec = '''
name: app
dependencies:
  app_debugger:
    path: ../../features/app_debugger/app_debugger
''';

    late Directory root;
    late Directory previousCwd;
    late File pubspec;

    void writeConfig(String extra) =>
        File(p.join(root.path, 'build_prepare.yaml')).writeAsStringSync('''
build_prepare:
  mappings:
    - debug: app_debugger
      release: app_debugger_noop
  target_paths:
    - apps/app
$extra''');

    void writeGraph(List<String> appDeps) {
      Directory(p.join(root.path, '.dart_tool')).createSync();
      File(p.join(root.path, '.dart_tool', 'package_graph.json'))
          .writeAsStringSync('''
{"roots": ["app"], "configVersion": 1, "packages": [
  {"name": "app", "dependencies": ${appDeps.map((d) => '"$d"').toList()}},
  {"name": "app_debugger", "dependencies": ["app_blackbox"]},
  {"name": "app_blackbox", "dependencies": ["app_blackbox_metrics"]},
  {"name": "app_blackbox_metrics", "dependencies": []},
  {"name": "app_debugger_noop", "dependencies": []}
]}''');
    }

    void writePlugins(List<String> names, {bool dev = false}) =>
        File(p.join(root.path, 'apps/app/.flutter-plugins-dependencies'))
            .writeAsStringSync(
              '''
{"plugins": {"android": [${names.map((n) => '{"name": "$n", "dev_dependency": $dev}').join(',')}]}}''',
            );

    bool swapped() => pubspec.readAsStringSync().contains('app_debugger_noop');

    setUp(() {
      previousCwd = Directory.current;
      root = Directory.systemTemp.createTempSync('build_prepare_flavor_');
      File(p.join(root.path, 'pubspec.yaml'))
          .writeAsStringSync('name: ws\nworkspace:\n  - apps/app\n');
      writeConfig('');
      Directory(p.join(root.path, 'apps/app')).createSync(recursive: true);
      pubspec = File(p.join(root.path, 'apps/app/pubspec.yaml'))
        ..writeAsStringSync(appPubspec);
      Directory.current = root.path;
    });

    tearDown(() {
      Directory.current = previousCwd;
      root.deleteSync(recursive: true);
    });

    for (final flavor in ['development', 'staging', 'alpha', 'beta']) {
      test('internal flavor $flavor keeps the debug packages', () async {
        expect(await BuildPrepareRunner().run(['--flavor', flavor]), 0);
        expect(pubspec.readAsStringSync(), appPubspec);
      });
    }

    test('production gets the noop twins', () async {
      expect(await BuildPrepareRunner().run(['--flavor', 'production']), 0);
      expect(swapped(), isTrue);
      expect(pubspec.readAsStringSync(), isNot(contains('app_debugger:')));
    });

    test('an unknown flavor gets the noop twins (safe default)', () async {
      expect(await BuildPrepareRunner().run(['--flavor', 'prod_eu']), 0);
      expect(swapped(), isTrue);
    });

    group('noop mirror guard', () {
      void writeApp() {
        File(p.join(root.path, 'apps/app/lib/main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync("import 'package:app_debugger/testing.dart';\n");
      }

      void writeNoop({required bool withTesting}) {
        final lib = Directory(
          p.join(root.path, 'features/app_debugger/app_debugger_noop/lib'),
        )..createSync(recursive: true);
        if (withTesting) File(p.join(lib.path, 'testing.dart')).createSync();
      }

      test('fails the swap; the miss names the file and library', () async {
        writeApp();
        writeNoop(withTesting: false);
        expect(await BuildPrepareRunner().run(['--flavor', 'production']), 1);
        expect(BuildPrepareState.exists(root.path), isTrue);

        final misses = BuildPrepareCommand.findMissingMirrors(
          targetDir: Directory(p.join(root.path, 'apps/app')),
          toDep: 'app_debugger_noop',
          rewrites: [
            const DartImportRewriteResult(
              filePath: 'apps/app/lib/main.dart',
              from: 'app_debugger',
              to: 'app_debugger_noop',
            ),
          ],
          rootPath: root.path,
        );
        expect(misses, hasLength(1));
        expect(misses.single, contains('apps/app/lib/main.dart'));
        expect(
          misses.single,
          contains('package:app_debugger_noop/testing.dart'),
        );
      });

      test('passes when the noop mirrors the library', () async {
        writeApp();
        writeNoop(withTesting: true);
        expect(await BuildPrepareRunner().run(['--flavor', 'production']), 0);
      });
    });

    test('internal_flavors in the config replaces the default', () async {
      writeConfig('  internal_flavors: [qa]\n');
      await BuildPrepareRunner().run(['--flavor', 'qa']);
      expect(swapped(), isFalse);

      await BuildPrepareRunner().run(['--flavor', 'staging']);
      expect(swapped(), isTrue);
    });

    test('release/debug stay as aliases; an explicit mode wins', () async {
      await BuildPrepareRunner().run(['release', '--flavor', 'alpha']);
      expect(swapped(), isTrue);

      await BuildPrepareRunner().run(['debug']);
      expect(pubspec.readAsStringSync(), appPubspec);
    });

    test('an internal flavor after a production swap restores the debug '
        'packages', () async {
      await BuildPrepareRunner().run(['--flavor', 'production']);
      await BuildPrepareRunner().run(['--flavor', 'beta']);
      expect(pubspec.readAsStringSync(), appPubspec);
    });

    test('fails without a mode or a flavor', () async {
      expect(await BuildPrepareRunner().run([]), 1);
    });

    test('leak check fails on a seeded leak in the dependency graph', () async {
      writeGraph(['app_debugger']);
      expect(
        await BuildPrepareRunner().run([
          '--check-leaks',
          '--flavor',
          'production',
        ]),
        1,
      );
    });

    test('leak check passes on a clean production graph', () async {
      writeGraph(['app_debugger_noop']);
      writePlugins(['path_provider_android']);
      expect(
        await BuildPrepareRunner().run([
          '--check-leaks',
          '--flavor',
          'production',
        ]),
        0,
      );
    });

    test('leak check is skipped for an internal flavor', () async {
      writeGraph(['app_debugger']);
      expect(
        await BuildPrepareRunner().run(['--check-leaks', '--flavor', 'alpha']),
        0,
      );
    });

    test('leak check fails when there is nothing to check', () async {
      expect(
        await BuildPrepareRunner().run([
          '--check-leaks',
          '--flavor',
          'production',
        ]),
        1,
      );
    });

    test('findLeaks reports debug_only packages through the graph and the '
        'plugin list, and ignores dev-only plugins', () {
      writeGraph(['app_debugger']);
      writePlugins(['app_blackbox_metrics']);

      final leaks = BuildPrepareCommand.findLeaks(
        rootPath: root.path,
        targetPaths: ['apps/app'],
        forbidden: {'app_debugger', 'app_blackbox_metrics'},
      );
      expect(leaks, [
        'apps/app dependency: app_debugger',
        'apps/app dependency: app_blackbox_metrics',
        'apps/app plugin: app_blackbox_metrics',
      ]);

      writeGraph(['app_debugger_noop']);
      writePlugins(['app_blackbox_metrics'], dev: true);
      expect(
        BuildPrepareCommand.findLeaks(
          rootPath: root.path,
          targetPaths: ['apps/app'],
          forbidden: {'app_debugger', 'app_blackbox_metrics'},
        ),
        isEmpty,
      );
    });

    test('findLeaks reads pubspec.lock', () {
      File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  app_debugger:
    source: path
''');
      expect(
        BuildPrepareCommand.findLeaks(
          rootPath: root.path,
          targetPaths: ['apps/app'],
          forbidden: {'app_debugger'},
        ),
        ['pubspec.lock: app_debugger'],
      );
    });
  });

  group('build-mode swap and leak check (debug_build_only)', () {
    const appPubspec = '''
name: app
dependencies:
  app_debugger:
    path: ../../features/app_debugger/app_debugger
  app_marionette:
    path: ../../features/app_marionette/app_marionette
''';

    late Directory root;
    late Directory previousCwd;
    late File pubspec;

    void writeGraph(List<String> appDeps) {
      Directory(p.join(root.path, '.dart_tool')).createSync();
      File(p.join(root.path, '.dart_tool', 'package_graph.json'))
          .writeAsStringSync('''
{"roots": ["app"], "configVersion": 1, "packages": [
  {"name": "app", "dependencies": ${appDeps.map((d) => '"$d"').toList()}},
  {"name": "app_marionette", "dependencies": ["marionette_flutter"]},
  {"name": "marionette_flutter", "dependencies": []},
  {"name": "app_marionette_noop", "dependencies": []},
  {"name": "app_debugger", "dependencies": []}
]}''');
    }

    String deps() => pubspec.readAsStringSync();
    Future<int> run(List<String> args) => BuildPrepareRunner().run(args);

    setUp(() {
      previousCwd = Directory.current;
      root = Directory.systemTemp.createTempSync('build_prepare_mode_');
      File(p.join(root.path, 'pubspec.yaml'))
          .writeAsStringSync('name: ws\nworkspace:\n  - apps/app\n');
      File(p.join(root.path, 'build_prepare.yaml')).writeAsStringSync('''
build_prepare:
  mappings:
    - debug: app_debugger
      release: app_debugger_noop
  debug_build_only:
    - debug: app_marionette
      release: app_marionette_noop
    - marionette_flutter
  target_paths:
    - apps/app
''');
      Directory(p.join(root.path, 'apps/app')).createSync(recursive: true);
      pubspec = File(p.join(root.path, 'apps/app/pubspec.yaml'))
        ..writeAsStringSync(appPubspec);
      Directory.current = root.path;
    });

    tearDown(() {
      Directory.current = previousCwd;
      root.deleteSync(recursive: true);
    });

    test('parses mappings and bare packages', () {
      final config = BuildPrepareConfig.fromYamlFile('build_prepare.yaml')!;
      expect(config.debugBuildOnly.single.debug, 'app_marionette');
      expect(config.debugBuildOnlyPackages, ['marionette_flutter']);
      expect(config.mappings.map((m) => m.debug), ['app_debugger']);
    });

    for (final mode in ['release', 'profile']) {
      test('--mode $mode swaps it for an internal flavor, keeping the '
          'flavor tooling', () async {
        expect(await run(['--flavor', 'alpha', '--mode', mode]), 0);
        expect(deps(), contains('app_marionette_noop:'));
        expect(deps(), isNot(contains('app_marionette:')));
        expect(deps(), contains('app_debugger:'));
      });
    }

    test('--mode release with production swaps both lists', () async {
      expect(await run(['--flavor', 'production', '--mode', 'release']), 0);
      expect(deps(), contains('app_marionette_noop:'));
      expect(deps(), contains('app_debugger_noop:'));
    });

    test('--mode debug with production keeps Marionette only', () async {
      expect(await run(['--flavor', 'production', '--mode', 'debug']), 0);
      expect(deps(), contains('app_marionette:'));
      expect(deps(), contains('app_debugger_noop:'));
    });

    test('--mode alone needs no flavor', () async {
      expect(await run(['--mode', 'release']), 0);
      expect(deps(), contains('app_marionette_noop:'));
      expect(deps(), contains('app_debugger:'));
    });

    test('without --mode the list is left as it is', () async {
      await run(['--flavor', 'production']);
      expect(deps(), contains('app_marionette:'));
      expect(deps(), contains('app_debugger_noop:'));
    });

    test('the release alias swaps it too', () async {
      await run(['release']);
      expect(deps(), contains('app_marionette_noop:'));
    });

    test('--mode debug restores it byte-for-byte', () async {
      await run(['--flavor', 'alpha', '--mode', 'release']);
      expect(await run(['--flavor', 'alpha', '--mode', 'debug']), 0);
      expect(deps(), appPubspec);
    });

    test('the debug alias restores it', () async {
      await run(['--flavor', 'production', '--mode', 'release']);
      await run(['debug']);
      expect(deps(), appPubspec);
    });

    test('--restore restores it, also after two unrestored swaps', () async {
      await run(['--flavor', 'alpha', '--mode', 'release']);
      await run(['--flavor', 'production']);
      expect(await run(['--restore']), 0);
      expect(deps(), appPubspec);
    });

    test('the missing-mirror guard covers the build-mode noop', () async {
      File(p.join(root.path, 'apps/app/lib/main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          "import 'package:app_marionette/app_marionette.dart';\n",
        );
      final noopLib = Directory(
        p.join(root.path, 'features/app_marionette/app_marionette_noop/lib'),
      )..createSync(recursive: true);

      expect(await run(['--flavor', 'alpha', '--mode', 'release']), 1);
      await run(['--restore']);

      File(p.join(noopLib.path, 'app_marionette_noop.dart')).createSync();
      expect(await run(['--flavor', 'alpha', '--mode', 'release']), 0);
      expect(
        File(p.join(root.path, 'apps/app/lib/main.dart')).readAsStringSync(),
        contains('package:app_marionette_noop/app_marionette_noop.dart'),
      );
    });

    test(
      'leak check fails on Marionette in an internal release graph',
      () async {
        writeGraph(['app_marionette', 'app_debugger']);
        expect(
          await run([
            '--check-leaks',
            '--flavor',
            'alpha',
            '--mode',
            'release',
          ]),
          1,
        );
        // Default mode is release.
        expect(await run(['--check-leaks', '--flavor', 'alpha']), 1);
        expect(
          await run([
            '--check-leaks',
            '--flavor',
            'alpha',
            '--mode',
            'profile',
          ]),
          1,
        );
      },
    );

    test('leak check fails on a direct marionette_flutter dependency', () {
      writeGraph(['marionette_flutter']);
      expect(
        BuildPrepareCommand.findLeaks(
          rootPath: root.path,
          targetPaths: ['apps/app'],
          forbidden: {'app_marionette', 'marionette_flutter'},
        ),
        ['apps/app dependency: marionette_flutter'],
      );
    });

    test('leak check passes on a swapped release graph although the '
        'workspace lock still lists marionette_flutter', () async {
      writeGraph(['app_marionette_noop', 'app_debugger']);
      File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  marionette_flutter:
    source: hosted
''');
      expect(
        await run(['--check-leaks', '--flavor', 'alpha', '--mode', 'release']),
        0,
      );
    });

    test('leak check skips Marionette for --mode debug', () async {
      writeGraph(['app_marionette', 'app_debugger']);
      expect(
        await run(['--check-leaks', '--flavor', 'alpha', '--mode', 'debug']),
        0,
      );
    });
  });

  group('BuildPrepareState', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('build_prepare_state_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    test('load returns null when state file is absent', () {
      expect(BuildPrepareState.load(tempRoot.path), isNull);
    });

    test('save then load round-trips content', () {
      const state = BuildPrepareState(
        files: [
          FileBackup(path: 'apps/x/pubspec.yaml', content: 'name: x'),
          FileBackup(path: 'apps/x/lib/main.dart', content: 'void main() {}'),
        ],
      );

      BuildPrepareState.save(tempRoot.path, state);
      final loaded = BuildPrepareState.load(tempRoot.path);

      expect(loaded, isNotNull);
      expect(loaded!.files, hasLength(2));
      expect(loaded.files[0].path, 'apps/x/pubspec.yaml');
      expect(loaded.files[0].content, 'name: x');
      expect(loaded.files[1].path, 'apps/x/lib/main.dart');
      expect(loaded.files[1].content, 'void main() {}');
    });

    test('exists reports state file presence', () {
      expect(BuildPrepareState.exists(tempRoot.path), isFalse);
      BuildPrepareState.save(tempRoot.path, const BuildPrepareState(files: []));
      expect(BuildPrepareState.exists(tempRoot.path), isTrue);
    });

    test('delete removes the state file', () {
      BuildPrepareState.save(tempRoot.path, const BuildPrepareState(files: []));
      expect(BuildPrepareState.exists(tempRoot.path), isTrue);

      BuildPrepareState.delete(tempRoot.path);

      expect(BuildPrepareState.exists(tempRoot.path), isFalse);
    });

    test('delete is idempotent when state file is absent', () {
      // Should not throw.
      expect(() => BuildPrepareState.delete(tempRoot.path), returnsNormally);
    });

    test('load returns null for malformed JSON', () {
      File(p.join(tempRoot.path, BuildPrepareState.stateFileName))
          .writeAsStringSync('{not valid json');

      expect(BuildPrepareState.load(tempRoot.path), isNull);
    });
  });
}
