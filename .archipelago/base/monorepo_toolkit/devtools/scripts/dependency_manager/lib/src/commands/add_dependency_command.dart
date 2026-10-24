import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/barrel_file_service.dart';
import 'package:dependency_manager/src/services/dependency_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// A command to add a dependency to the shared dependencies package.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit deps add <package> -v <version> -c <category>
/// ```
class DepsAddCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsAddCommand].
  this {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'The version constraint for the package.',
      )
      ..addOption(
        'category',
        abbr: 'c',
        help: 'The category/barrel file to add the export to.',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  late final DependencyService _dependencyService;
  late final BarrelFileService _barrelFileService;

  @override
  String get name => 'add';

  @override
  String get description =>
      'Add a dependency to the shared dependencies package.';

  @override
  String get invocation => 'deps add <package_name>';

  @override
  Future<int> run() async {
    final rootPath = MonorepoFinder.findRoot();
    if (rootPath == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    final dependenciesPath = _findDependenciesPath(rootPath);
    _dependencyService = DependencyService(
      dependenciesPackagePath: dependenciesPath,
    );
    _barrelFileService = BarrelFileService(
      dependenciesLibPath: '$dependenciesPath/lib',
    );

    if (argResults!.rest.isEmpty) {
      _logger.error('Please provide a package name.');
      _logger.info('Usage: deps add <package_name>');
      return 64; // EX_USAGE
    }

    final packageName = argResults!.rest.first;

    // Support both flag-based and positional arguments
    final version =
        argResults!['version'] as String? ??
        (argResults!.rest.length > 1 ? argResults!.rest[1] : null);

    final category =
        argResults!['category'] as String? ??
        (argResults!.rest.length > 2 ? argResults!.rest[2] : null);

    // Check if dependency already exists
    final exists = await _dependencyService.dependencyExists(packageName);
    if (exists) {
      _logger.warning('Dependency "$packageName" already exists.');
      return 0;
    }

    // Add dependency to pubspec.yaml
    _logger.progress('Adding $packageName to pubspec.yaml');
    try {
      await _dependencyService.addDependency(
        packageName: packageName,
        version: version,
      );
      _logger.success('Added $packageName to pubspec.yaml');
    } catch (e) {
      _logger.error('Failed to add $packageName: $e');
      return 1;
    }

    // Add to barrel file if category specified
    if (category == null) {
      _logger.info(
        'No category specified. Use -c <category> to add to a barrel file.',
      );
      return 0;
    }

    // Create barrel file if it doesn't exist
    if (!_barrelFileService.barrelFileExists(category)) {
      _logger.progress('Creating $category.dart');
      try {
        await _barrelFileService.createBarrelFile(
          category: category,
          description: category[0].toUpperCase() + category.substring(1),
        );
        await _barrelFileService.addBarrelToDependencies(category);
        _logger.success('Created $category.dart');
      } catch (e) {
        _logger.error('Failed to create $category.dart: $e');
        return 1;
      }
    }

    // Add export to barrel file
    _logger.progress('Adding export to $category.dart');
    try {
      await _barrelFileService.addExportToBarrelFile(
        category: category,
        packageName: packageName,
      );
      _logger.success('Added export to $category.dart');
    } catch (e) {
      _logger.error('Failed to add export: $e');
      return 1;
    }

    _logger.success(
      'Successfully added "$packageName" to dependencies/$category.dart',
    );
    _logger.info("Import with: import 'package:dependencies/$category.dart';");

    return 0;
  }

  String _findDependenciesPath(String rootPath) =>
      '$rootPath/shared/dependencies';
}
