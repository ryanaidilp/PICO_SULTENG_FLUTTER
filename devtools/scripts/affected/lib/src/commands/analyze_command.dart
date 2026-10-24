import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run flutter analyze on affected packages.
class AnalyzeCommand() extends Command<int> {
  /// Creates a new [AnalyzeCommand].
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
      )
      ..addFlag(
        'fatal-infos',
        help: 'Treat info-level issues as fatal (flutter analyze default).',
        defaultsTo: true,
      )
      ..addFlag(
        'fatal-warnings',
        help: 'Treat warnings as fatal (flutter analyze default).',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Run flutter analyze on affected packages.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final failFast = argResults!['fail-fast'] as bool;
    final command = [
      'flutter analyze',
      if (!(argResults!['fatal-infos'] as bool)) '--no-fatal-infos',
      if (!(argResults!['fatal-warnings'] as bool)) '--no-fatal-warnings',
      'lib',
    ].join(' ');
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
        ..info('Running: $command');

      final exitCode = await service.runInPackages(
        packages: affectedPackages.toList(),
        commandString: command,
        failFast: failFast,
        requiredDir: 'lib',
      );

      return exitCode;
    } on Exception catch (e) {
      logger.error('Failed to run analyze: $e');
      return 1;
    }
  }
}
