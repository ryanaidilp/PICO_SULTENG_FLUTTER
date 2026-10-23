import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/workspace_locator.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A command to add an internal (workspace) package as a dependency.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit deps internal <source_package> <target_package>
/// ```
///
/// This adds `target_package` as a dependency to `source_package`.
class DepsInternalCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsInternalCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'internal';

  @override
  String get description =>
      'Add an internal workspace package as a dependency to another package.';

  @override
  String get invocation =>
      'deps internal <source_package> <target_package>\n'
      '  Adds target_package as a dependency to source_package.';

  @override
  Future<int> run() async {
    if (argResults!.rest.length < 2) {
      _logger
        ..error('Please provide source and target package names.')
        ..info('')
        ..info('Usage: deps internal <source_package> <target_package>')
        ..info('  Adds target_package as a dependency to source_package.');
      return 64;
    }

    final sourcePackage = argResults!.rest[0];
    final targetPackage = argResults!.rest[1];

    final monorepoRoot = MonorepoFinder.findRoot();
    if (monorepoRoot == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    // Find source package path
    final sourcePackagePath = await findWorkspacePackagePath(
      monorepoRoot,
      sourcePackage,
    );
    if (sourcePackagePath == null) {
      _logger.error('Could not find package "$sourcePackage" in workspace.');
      return 1;
    }

    // Find target package path (to verify it exists)
    final targetPackagePath = await findWorkspacePackagePath(
      monorepoRoot,
      targetPackage,
    );
    if (targetPackagePath == null) {
      _logger.error('Could not find package "$targetPackage" in workspace.');
      return 1;
    }

    // Check if dependency already exists
    final pubspecPath = path.join(sourcePackagePath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      _logger.error('pubspec.yaml not found at $pubspecPath');
      return 1;
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;
    final dependencies = yaml?['dependencies'] as YamlMap?;

    if (dependencies?.containsKey(targetPackage) ?? false) {
      _logger.warning(
        'Dependency "$targetPackage" already exists in "$sourcePackage".',
      );
      return 0;
    }

    // Calculate relative path from source to target
    final relativePath = path.relative(
      targetPackagePath,
      from: sourcePackagePath,
    );

    // Add the dependency
    _logger.progress('Adding "$targetPackage" to "$sourcePackage"');

    try {
      final editor = YamlEditor(content);
      editor.update(['dependencies', targetPackage], {'path': relativePath});

      await pubspecFile.writeAsString(editor.toString());
      _logger.success('Added "$targetPackage" to "$sourcePackage"');
    } catch (e) {
      _logger.error('Failed to add dependency: $e');
      return 1;
    }

    _logger
      ..success('Successfully added "$targetPackage" to "$sourcePackage"')
      ..info(
        "Import with: import 'package:$targetPackage/$targetPackage.dart';",
      );

    return 0;
  }
}
