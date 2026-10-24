import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:workspace_setup/src/services/workspace_service.dart';

/// Validates the health of the Dart workspace.
///
/// Checks:
/// 1. All packages discovered by globs have `resolution: workspace`.
/// 2. No duplicate `dependency_overrides` across workspace packages
///    (same package overridden in multiple pubspec.yaml files).
///
/// When issues are found, the command prints actionable guidance and exits
/// with a non-zero status code so it can be used in CI pipelines.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit workspace validate
/// ```
class ValidateCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [ValidateCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validates workspace health: checks resolution flags and detects '
      'duplicate dependency_overrides across packages.';

  @override
  Future<int> run() async {
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
          'Workspace field does not use glob patterns. '
          'Run "workspace setup" to migrate to Dart 3.11+ globs.',
        );
      }

      _logger.progress('Expanding workspace glob patterns...');
      final packages = await service.expandGlobPatterns();

      if (packages.isEmpty) {
        _logger.warning(
          'No packages matched by workspace glob patterns. '
          'Check the workspace field in root pubspec.yaml.',
        );
        return 1;
      }

      _logger.info('Found ${packages.length} packages via globs.');

      var hasErrors = false;

      // --- Check 1: resolution: workspace ---
      _logger.info('');
      _logger.progress('Checking "resolution: workspace" on all packages...');
      final resolutionResults = await service.checkAllResolutions();
      final missingResolution = resolutionResults
          .where((r) => !r.hasResolution)
          .toList();

      if (missingResolution.isEmpty) {
        _logger.success(
          'All ${packages.length} packages have "resolution: workspace".',
        );
      } else {
        hasErrors = true;
        _logger.error(
          '${missingResolution.length} package(s) are missing '
          '"resolution: workspace":',
        );
        for (final r in missingResolution) {
          _logger.warning('  ! ${r.packagePath}');
        }
        _logger.info('');
        _logger.info(
          'Fix: run "dart run monorepo_toolkit workspace fix-resolution"',
        );
        _logger.info(
          'Or, to temporarily resolve a package independently without '
          'workspace resolution, create a pubspec_overrides.yaml with an '
          'empty "resolution:" field next to its pubspec.yaml.',
        );
      }

      // --- Check 2: duplicate dependency_overrides ---
      _logger.info('');
      _logger.progress(
        'Checking for duplicate dependency_overrides across packages...',
      );
      final conflicts = await service.detectOverrideConflicts();

      if (conflicts.isEmpty) {
        _logger.success('No duplicate dependency_overrides found.');
      } else {
        hasErrors = true;
        _logger.error(
          '${conflicts.length} dependency override conflict(s) detected:',
        );
        for (final conflict in conflicts) {
          _logger.warning('  Dependency: "${conflict.dependency}"');
          _logger.warning(
            '  Overridden in ${conflict.packages.length} packages:',
          );
          for (final pkg in conflict.packages) {
            _logger.warning('    - $pkg');
          }
        }
        _logger.info('');
        _logger.info(
          'Recommendation: centralize shared dependency_overrides in the '
          'root pubspec.yaml and remove duplicates from individual packages. '
          'This avoids version conflicts and makes overrides easier to manage.',
        );
      }

      // --- Summary ---
      _logger.info('');
      if (hasErrors) {
        _logger.error('Workspace validation FAILED. Fix the issues above.');
        return 1;
      }

      _logger.success(
        'Workspace validation passed. ${packages.length} packages OK.',
      );
      return 0;
    } catch (e) {
      _logger.error('Failed: $e');
      return 1;
    }
  }
}
