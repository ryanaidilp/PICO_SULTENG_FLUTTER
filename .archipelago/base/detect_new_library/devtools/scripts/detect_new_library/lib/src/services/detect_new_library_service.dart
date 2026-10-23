import 'dart:io';

import 'package:detect_new_library/src/models/new_library_config.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

class const NewLibraryFinding({
  required final String pubspecPath,
  required final Set<String> addedPackages,
});

class const DetectNewLibraryService({
  required final String rootPath,
  required final NewLibraryConfig config,
}) {
  static NewLibraryConfig loadConfig(String rootPath) {
    final configFile = File(p.join(rootPath, '.newlibrary.yaml'));
    if (!configFile.existsSync()) return const NewLibraryConfig();
    final yaml = loadYaml(configFile.readAsStringSync()) as Map?;
    if (yaml == null) return const NewLibraryConfig();
    return NewLibraryConfig.fromYaml(yaml);
  }

  Future<List<NewLibraryFinding>> findNewDependencies({
    String? baseBranch,
  }) async {
    final base = baseBranch ?? config.baseBranch ?? await _detectBaseBranch();
    final changedPubspecs = await _getChangedPubspecs(base);
    final findings = <NewLibraryFinding>[];

    for (final pubspecPath in changedPubspecs) {
      final baseContent = await _getFileAtRef('origin/$base', pubspecPath);
      if (baseContent == null) continue; // new package entirely — skip

      final currentFile = File(p.join(rootPath, pubspecPath));
      if (!currentFile.existsSync()) continue;
      final currentContent = currentFile.readAsStringSync();

      final newDeps = findNewDeps(
        baseContent: baseContent,
        currentContent: currentContent,
      ).difference(config.ignoredPackages.toSet());

      if (newDeps.isNotEmpty) {
        findings.add(
          NewLibraryFinding(pubspecPath: pubspecPath, addedPackages: newDeps),
        );
      }
    }

    return findings;
  }

  // Static helpers are public so tests can call them without a real git repo.
  static Set<String> extractDepsFromContent(String content) {
    final yaml = loadYaml(content);
    if (yaml is! Map) return {};
    final deps = <String>{};
    for (final section in ['dependencies', 'dev_dependencies']) {
      final block = yaml[section];
      if (block is! Map) continue;
      for (final key in block.keys) {
        final name = key as String;
        final value = block[name];
        // Skip SDK constraints: `flutter: {sdk: flutter}`
        if (value is Map && value.containsKey('sdk')) continue;
        deps.add(name);
      }
    }
    return deps;
  }

  static Set<String> findNewDeps({
    required String baseContent,
    required String currentContent,
  }) {
    final baseDeps = extractDepsFromContent(baseContent);
    final currentDeps = extractDepsFromContent(currentContent);
    return currentDeps.difference(baseDeps);
  }

  Future<String> _detectBaseBranch() async {
    final ciBase =
        Platform.environment['GITHUB_BASE_REF'] ??
        Platform.environment['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'];
    if (ciBase != null && ciBase.isNotEmpty) return ciBase;
    final result = await ShellRunner.run(
      'git branch --list develop',
      workingDirectory: rootPath,
    );
    if (result.stdout.toString().trim().isNotEmpty) return 'develop';
    return 'main';
  }

  Future<List<String>> _getChangedPubspecs(String base) async {
    final result = await ShellRunner.run(
      'git diff --name-only --diff-filter=M origin/$base...HEAD',
      workingDirectory: rootPath,
    );
    if (result.exitCode != 0) {
      // Warn so CI operators know the scan was skipped, not that there were no changes.
      stderr.writeln(
        '[detect-new-library] Warning: git diff failed (exit ${result.exitCode}). '
        'Skipping pubspec scan.',
      );
      return [];
    }
    return result.stdout
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.endsWith('pubspec.yaml'))
        .toList();
  }

  Future<String?> _getFileAtRef(String ref, String filePath) async {
    final result = await ShellRunner.run(
      'git show $ref:$filePath',
      workingDirectory: rootPath,
    );
    if (result.exitCode != 0) return null;
    return result.stdout.toString();
  }
}
