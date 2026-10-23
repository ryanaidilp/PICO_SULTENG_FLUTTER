import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run flutter test --update-goldens on affected packages.
///
/// Use --check to verify goldens without updating (runs tests tagged "golden").
class GoldenCommand() extends Command<int> {
  /// Creates a new [GoldenCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addFlag(
        'check',
        help:
            'Verify goldens without updating '
            '(runs flutter test --tags golden).',
        negatable: false,
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package failure.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'golden';

  @override
  String get description =>
      'Run flutter test --update-goldens on affected packages. '
      'Use --check to verify without updating.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final checkOnly = argResults!['check'] as bool;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    final command = checkOnly
        ? 'flutter test --tags golden'
        : 'flutter test --update-goldens';

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
        ..info('Running: $command');

      return await service.runInPackages(
        packages: affectedPackages.toList(),
        commandString: command,
        failFast: failFast,
        requiredDir: 'test',
      );
    } on Exception catch (e) {
      logger.error('Failed to run golden tests: $e');
      return 1;
    }
  }
}
