import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/barrel_file_service.dart';
import 'package:dependency_manager/src/services/dependency_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// A command to remove a dependency from the shared dependencies package.
///
/// Usage:
/// ```bash
/// monorepo_toolkit deps remove <package_name> [--force]
/// ```
class DepsRemoveCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsRemoveCommand].
  this {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip confirmation prompt (required for non-interactive mode).',
      negatable: false,
    );
  }

  final CliLogger _logger = logger ?? CliLogger();

  late final DependencyService _dependencyService;
  late final BarrelFileService _barrelFileService;

  @override
  String get name => 'remove';

  @override
  String get description =>
      'Remove a dependency from the shared dependencies package.';

  @override
  String get invocation => 'deps remove <package_name>';

  @override
  Future<int> run() async {
    final rootPath = MonorepoFinder.findRoot();
    if (rootPath == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    final dependenciesPath = '$rootPath/shared/dependencies';
    _dependencyService = DependencyService(
      dependenciesPackagePath: dependenciesPath,
    );
    _barrelFileService = BarrelFileService(
      dependenciesLibPath: '$dependenciesPath/lib',
    );

    if (argResults!.rest.isEmpty) {
      _logger.error('Please provide a package name.');
      _logger.info('Usage: deps remove <package_name>');
      return 64; // EX_USAGE
    }

    final packageName = argResults!.rest.first;

    // Check if dependency exists
    final exists = await _dependencyService.dependencyExists(packageName);
    if (!exists) {
      _logger.error('Dependency "$packageName" does not exist.');
      return 64;
    }

    // Remove from pubspec.yaml
    _logger.progress('Removing $packageName from pubspec.yaml');
    try {
      await _dependencyService.removeDependency(packageName: packageName);
      _logger.success('Removed $packageName from pubspec.yaml');
    } catch (e) {
      _logger.error('Failed to remove $packageName: $e');
      return 1;
    }

    // Remove export from barrel files
    _logger.progress('Removing exports from barrel files');
    try {
      await _barrelFileService.removeExportFromAllBarrelFiles(
        packageName: packageName,
      );
      _logger.success('Removed exports from barrel files');
    } catch (e) {
      _logger.error('Failed to remove exports: $e');
      return 1;
    }

    _logger.success('Successfully removed "$packageName" from dependencies');
    return 0;
  }
}
