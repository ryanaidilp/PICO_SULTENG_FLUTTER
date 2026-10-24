import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/dependency_audit.dart';
import 'package:dependency_manager/src/services/pub_failure_parser.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

/// Runs `dart pub get` and, when version solving fails, summarizes the
/// conflict and suggests `deps align` commands.
class DepsDiagnoseCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsDiagnoseCommand].
  this {
    argParser.addFlag(
      'write-overrides',
      help:
          'Write the highest conflicting constraint of each package to '
          'pubspec_overrides.yaml and retry. Hides the real conflict.',
      negatable: false,
    );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'diagnose';

  @override
  String get description =>
      'Run dart pub get and explain a version-solving failure.';

  @override
  Future<int> run() async {
    final root = MonorepoFinder.findRoot();
    if (root == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    final result = await _pubGet(root);
    if (result.exitCode == 0) {
      _logger.success('dart pub get succeeded.');
      return 0;
    }

    final output = '${result.stdout}\n${result.stderr}';
    final conflicts = parsePubFailure(output);
    if (conflicts.isEmpty) {
      _logger
        ..error('dart pub get failed; no conflicting constraints found:')
        ..info(output.trim());
      return 1;
    }

    final pinned = {
      for (final p in await readWorkspacePins(root))
        for (final e in p.all) e.key,
    };
    for (final c in conflicts) {
      _logger.warning('${c.package} is required with different constraints:');
      for (final r in c.requirements.entries) {
        _logger.info('  ${r.key}: ${r.value.join(', ')}');
      }
      _logger.info(
        pinned.contains(c.package)
            ? '  fix: deps align ${c.package}'
            : '  ${c.package} is only a transitive dependency; no direct '
                  'pin to align. Change the dependent or use --write-overrides.',
      );
    }

    if (!(argResults!['write-overrides'] as bool)) return 1;

    _writeOverrides(root, conflicts);
    _logger.warning(
      'Wrote pubspec_overrides.yaml. Overrides hide the real conflict; '
      'do not commit it, and fix the pins instead.',
    );
    final retry = await _pubGet(root);
    if (retry.exitCode != 0) {
      _logger.error(
        'dart pub get still fails:\n${retry.stdout}${retry.stderr}',
      );
      return 1;
    }
    _logger.success('dart pub get succeeded with overrides.');
    return 0;
  }

  Future<ProcessResult> _pubGet(String root) {
    _logger.progress('Running dart pub get');
    return ShellRunner.runDart(['pub', 'get'], workingDirectory: root);
  }

  // pubspec_overrides.yaml replaces the root pubspec's dependency_overrides,
  // so existing ones (e.g. vendored patches) are carried over.
  void _writeOverrides(String root, List<PubConflict> conflicts) {
    final file = File(path.join(root, 'pubspec_overrides.yaml'));
    final existing = <String, Object?>{
      ..._overridesIn(File(path.join(root, 'pubspec.yaml'))),
      ..._overridesIn(file),
    };
    final overrides = <String, Object?>{
      ...existing,
      for (final c in conflicts)
        c.package: highestConstraint(c.requirements.keys),
    };
    // JSON values are valid YAML, so quoting and path maps need no emitter.
    file.writeAsStringSync(
      '# Written by "deps diagnose --write-overrides". Overrides hide real\n'
      '# version conflicts; align the pins and delete this file.\n'
      'dependency_overrides:\n'
      '${overrides.entries.map((e) => '  ${e.key}: ${jsonEncode(e.value)}\n').join()}',
    );
  }

  Map<String, Object?> _overridesIn(File file) {
    if (!file.existsSync()) return {};
    final map = (loadYaml(
      file.readAsStringSync(),
    ) as YamlMap?)?['dependency_overrides'];
    return map is YamlMap ? Map<String, Object?>.from(_plain(map)! as Map) : {};
  }

  Object? _plain(Object? node) => switch (node) {
    YamlMap() => {for (final e in node.entries) e.key: _plain(e.value)},
    YamlList() => [for (final e in node) _plain(e)],
    _ => node,
  };
}
