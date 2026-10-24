import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/workspace_locator.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A command to add an external (pub.dev) dependency to a specific
/// internal package.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit deps external <target_package> <dependency> [version]
/// ```
class DepsExternalCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsExternalCommand].
  this {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'The version constraint for the package.',
      )
      ..addFlag(
        'dev',
        abbr: 'd',
        help: 'Add as a dev dependency.',
        negatable: false,
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'external';

  @override
  String get description =>
      'Add an external (pub.dev) dependency to a specific internal package.';

  @override
  String get invocation =>
      'deps external <target_package> <dependency> [version]\n'
      '  Adds an external dependency to the specified internal package.';

  @override
  Future<int> run() async {
    if (argResults!.rest.length < 2) {
      _logger
        ..error('Please provide target package and dependency name.')
        ..info('')
        ..info('Usage: deps external <target_package> <dependency> [version]');
      return 64;
    }

    final targetPackage = argResults!.rest[0];
    final dependencyName = argResults!.rest[1];

    // Support both flag-based and positional arguments
    final version =
        argResults!['version'] as String? ??
        (argResults!.rest.length > 2 ? argResults!.rest[2] : null);

    final isDev = argResults!['dev'] as bool;

    final monorepoRoot = MonorepoFinder.findRoot();
    if (monorepoRoot == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    // Find target package path
    final targetPackagePath = await findWorkspacePackagePath(
      monorepoRoot,
      targetPackage,
    );
    if (targetPackagePath == null) {
      _logger.error('Could not find package "$targetPackage" in workspace.');
      return 1;
    }

    // Check if dependency already exists
    final pubspecPath = path.join(targetPackagePath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      _logger.error('pubspec.yaml not found at $pubspecPath');
      return 1;
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    final dependencySection = isDev ? 'dev_dependencies' : 'dependencies';
    final dependencies = yaml?[dependencySection] as YamlMap?;

    if (dependencies?.containsKey(dependencyName) ?? false) {
      _logger.warning(
        'Dependency "$dependencyName" already exists in '
        '"$targetPackage" $dependencySection.',
      );
      return 0;
    }

    // Add the dependency
    _logger.progress('Adding "$dependencyName" to "$targetPackage"');

    try {
      final editor = YamlEditor(content);

      // Format version constraint
      String versionConstraint;
      if (version == null) {
        versionConstraint = 'any';
      } else if (version.startsWith('^') ||
          version.startsWith('>') ||
          version.startsWith('<') ||
          version.startsWith('=')) {
        versionConstraint = version;
      } else {
        versionConstraint = '^$version';
      }

      editor.update([dependencySection, dependencyName], versionConstraint);

      await pubspecFile.writeAsString(editor.toString());
      _logger.success('Added "$dependencyName" to "$targetPackage"');
    } catch (e) {
      _logger.error('Failed to add dependency: $e');
      return 1;
    }

    final depType = isDev ? 'dev dependency' : 'dependency';
    _logger
      ..success(
        'Successfully added "$dependencyName" as $depType to "$targetPackage"',
      )
      ..info(
        "Import with: import 'package:$dependencyName/$dependencyName.dart';",
      );

    return 0;
  }
}
