import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run `dart fix --dry-run` on affected packages and fail
/// if any package has fixes available.
///
/// Fast CI gate. `dart fix` itself does not expose a
/// `--set-exit-if-changed` flag, so this command parses stdout for
/// the "Nothing to fix!" sentinel message.
class FixCheckCommand() extends Command<int> {
  /// Creates a new [FixCheckCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package with fixes available.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'fix-check';

  @override
  String get description =>
      'Check for available dart fix on affected packages '
      '(dart fix --dry-run, fail if any fixes are suggested).';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final configPath = p.join(rootPath, 'affected.yaml');
      final config =
          AffectedConfig.fromYamlFile(configPath)?.withDefaults() ??
          const AffectedConfig().withDefaults();

      final service = AffectedService(rootPath: rootPath, config: config);
      final changedFiles = await service.getChangedFiles(baseBranch);

      if (changedFiles.isEmpty) {
        logger.info('No changes detected compared to $baseBranch.');
        return 0;
      }

      final affectedPackages = service.getAffectedWithDependents(changedFiles);

      if (affectedPackages.isEmpty) {
        logger.info('No packages affected by the changes.');
        return 0;
      }

      logger
        ..info('Comparing HEAD with $baseBranch...')
        ..info('Found ${affectedPackages.length} affected package(s)')
        ..info('Running: dart fix --dry-run');

      var hasFixes = false;

      for (final packagePath in affectedPackages.toList()..sort()) {
        final fullPath = p.join(rootPath, packagePath);
        final result = await ShellRunner.run(
          'dart fix --dry-run',
          workingDirectory: fullPath,
        );

        final stdout = result.stdout.toString();

        // `dart fix --dry-run` always exits 0. Detect outstanding
        // fixes via the absence of the "Nothing to fix!" sentinel.
        final clean = stdout.contains('Nothing to fix!');
        if (clean) {
          logger.success('[$packagePath] No fixes available.');
        } else {
          hasFixes = true;
          logger
            ..error('[$packagePath] Fixes available — run `dart fix --apply`:')
            ..info(stdout);
          if (failFast) return 1;
        }
      }

      return hasFixes ? 1 : 0;
    } on Exception catch (e) {
      logger.error('Failed to run fix-check: $e');
      return 1;
    }
  }
}
