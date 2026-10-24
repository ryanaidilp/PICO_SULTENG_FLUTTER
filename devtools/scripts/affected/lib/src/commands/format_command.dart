import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run `dart format --set-exit-if-changed .` on affected packages.
///
/// Fastest CI gate — runs first in the pipeline. Exits non-zero if any
/// affected package has files that would be modified by `dart format`.
class FormatCommand() extends Command<int> {
  /// Creates a new [FormatCommand].
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
        help: 'Stop on first package failure.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'format';

  @override
  String get description =>
      'Check formatting on affected packages '
      '(dart format --set-exit-if-changed .).';

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
        ..info('Running: dart format --set-exit-if-changed .');

      return await service.runInPackages(
        packages: affectedPackages.toList(),
        commandString: 'dart format --set-exit-if-changed .',
        failFast: failFast,
      );
    } on Exception catch (e) {
      logger.error('Failed to run format check: $e');
      return 1;
    }
  }
}
