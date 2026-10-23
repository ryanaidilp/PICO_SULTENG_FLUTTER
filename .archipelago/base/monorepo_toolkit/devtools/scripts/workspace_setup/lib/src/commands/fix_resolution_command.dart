import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:workspace_setup/src/services/workspace_service.dart';

/// Scans all packages matched by the workspace glob patterns in root
/// pubspec.yaml and adds `resolution: workspace` to any that are missing it.
///
/// This is the runtime replacement for the old `--fix-resolution` flag.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit workspace fix-resolution
/// dart run monorepo_toolkit workspace fix-resolution --dry-run
/// ```
class FixResolutionCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [FixResolutionCommand].
  this {
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Show what would be fixed without making changes.',
      negatable: false,
    );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'fix-resolution';

  @override
  String get description =>
      'Adds "resolution: workspace" to all packages matched by workspace '
      'glob patterns that are missing it.';

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

      // Verify workspace uses globs
      final usesGlobs = await service.workspaceUsesGlobs();
      if (!usesGlobs) {
        _logger.warning(
          'Workspace is not using glob patterns yet. '
          'Run "workspace setup" to migrate first.',
        );
      }

      _logger.progress('Expanding workspace glob patterns...');
      final packages = await service.expandGlobPatterns();

      if (packages.isEmpty) {
        _logger.warning('No packages matched by workspace glob patterns.');
        return 0;
      }

      _logger.info('Found ${packages.length} packages via globs.');

      // Check which are missing resolution: workspace
      final missing = <String>[];
      for (final pkg in packages) {
        final has = await service.hasResolutionWorkspace(pkg);
        if (!has) missing.add(pkg);
      }

      if (missing.isEmpty) {
        _logger.success(
          'All ${packages.length} packages already have '
          '"resolution: workspace".',
        );
        return 0;
      }

      _logger.info('');
      _logger.info(
        '${missing.length} package(s) missing "resolution: workspace":',
      );
      for (final pkg in missing) {
        _logger.warning('  ! $pkg');
      }

      if (isDryRun) {
        _logger.info('');
        _logger.info('Dry run — no changes made.');
        return 0;
      }

      _logger.progress('Adding "resolution: workspace"...');
      var fixed = 0;
      for (final pkg in missing) {
        final modified = await service.ensureResolutionWorkspace(pkg);
        if (modified) {
          fixed++;
          _logger.info('  + $pkg');
        }
      }

      _logger.success('Fixed $fixed package(s).');
      return 0;
    } catch (e) {
      _logger.error('Failed: $e');
      return 1;
    }
  }
}
