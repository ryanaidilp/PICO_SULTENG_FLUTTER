import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:workspace_setup/src/services/workspace_service.dart';

/// One-time migration command that converts an explicit workspace package list
/// to glob patterns (Dart 3.11+ feature).
///
/// If the workspace field already uses glob patterns, the command reports that
/// and exits cleanly without making any changes.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit workspace setup
/// dart run monorepo_toolkit workspace setup --dry-run
/// ```
class SetupCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [SetupCommand].
  this {
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Show what would be done without making changes.',
      negatable: false,
    );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'setup';

  @override
  String get description =>
      'One-time migration: converts explicit workspace package list to Dart '
      '3.11+ glob patterns. If already using globs, prints a notice and exits.';

  @override
  Future<int> run() async {
    final isDryRun = argResults!['dry-run'] as bool;

    try {
      final rootPath = MonorepoFinder.findRoot();

      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      _logger.info('Found monorepo root: $rootPath');

      final service = WorkspaceService(rootPath: rootPath);

      // Check if already using glob patterns
      final usesGlobs = await service.workspaceUsesGlobs();
      if (usesGlobs) {
        _logger.success(
          'Already using glob patterns in workspace field. '
          'No migration needed.',
        );
        _logger.info(
          'Use "workspace fix-resolution" to ensure all packages have '
          'resolution: workspace.',
        );
        _logger.info('Use "workspace validate" to check workspace health.');
        return 0;
      }

      // Get current explicit entries
      final currentEntries = await service.getRootWorkspaceEntries();

      if (currentEntries.isEmpty) {
        _logger.warning(
          'No workspace entries found in root pubspec.yaml. '
          'Scanning for packages...',
        );
        final packages = service.findAllPackages();

        if (packages.isEmpty) {
          _logger.warning('No packages found in the monorepo.');
          return 0;
        }

        final globs = service.convertToGlobPatterns(packages);
        _logger.info('Found ${packages.length} packages. Would convert to:');
        for (final glob in globs) {
          _logger.info('  $glob');
        }

        if (!isDryRun) {
          await service.updateWorkspaceEntries(globs);
          _logger.success(
            'Workspace field updated with ${globs.length} glob pattern(s).',
          );
        } else {
          _logger.info('Dry run — no changes made.');
        }

        return 0;
      }

      // Convert explicit entries to glob patterns
      _logger.info(
        'Found ${currentEntries.length} explicit workspace entries.',
      );
      _logger.info('Current entries:');
      for (final entry in currentEntries) {
        _logger.info('  $entry');
      }

      final globs = service.convertToGlobPatterns(currentEntries);
      _logger.info('');
      _logger.info('Proposed glob patterns (${globs.length}):');
      for (final glob in globs) {
        _logger.info('  $glob');
      }

      if (!isDryRun) {
        await service.updateWorkspaceEntries(globs);
        _logger.success(
          'Workspace field migrated to ${globs.length} glob pattern(s).',
        );
        _logger.info(
          'Run "workspace fix-resolution" to ensure all packages have '
          'resolution: workspace.',
        );
        _logger.info('Run "workspace validate" to verify workspace health.');
      } else {
        _logger.info('Dry run — no changes made.');
      }

      return 0;
    } catch (e) {
      _logger.error('Failed: $e');
      return 1;
    }
  }
}
