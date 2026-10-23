import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Finds the directory of the workspace package named [packageName].
///
/// Root `workspace:` entries may be literal paths or globs (`shared/*`,
/// `features/**`), as Dart 3.11 allows. Returns `null` when none matches.
Future<String?> findWorkspacePackagePath(
  String monorepoRoot,
  String packageName,
) async {
  final rootPubspec = File(path.join(monorepoRoot, 'pubspec.yaml'));
  if (!rootPubspec.existsSync()) return null;

  final yaml = loadYaml(await rootPubspec.readAsString()) as YamlMap?;
  final workspace = yaml?['workspace'] as YamlList?;
  if (workspace == null) return null;

  for (final entry in workspace) {
    final pubspecs = Glob('$entry/pubspec.yaml').list(root: monorepoRoot);
    await for (final entity in pubspecs) {
      final packageYaml =
          loadYaml(await File(entity.path).readAsString()) as YamlMap?;
      if (packageYaml?['name'] == packageName) return path.dirname(entity.path);
    }
  }
  return null;
}

/// Paths of every member `pubspec.yaml` listed by the root `workspace:`
/// entries (literal or glob), sorted, root excluded.
Future<List<String>> listWorkspacePubspecs(String monorepoRoot) async {
  final rootPubspec = File(path.join(monorepoRoot, 'pubspec.yaml'));
  if (!rootPubspec.existsSync()) return [];

  final yaml = loadYaml(await rootPubspec.readAsString()) as YamlMap?;
  final workspace = yaml?['workspace'] as YamlList?;
  if (workspace == null) return [];

  final found = <String>{};
  for (final entry in workspace) {
    await for (final entity in Glob(
      '$entry/pubspec.yaml',
    ).list(root: monorepoRoot)) {
      found.add(entity.path);
    }
  }
  return found.toList()..sort();
}
