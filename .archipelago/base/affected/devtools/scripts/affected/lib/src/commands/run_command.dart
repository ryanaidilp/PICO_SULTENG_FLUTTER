import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run a custom command on affected packages.
class RunCommand() extends Command<int> {
  /// Creates a new [RunCommand].
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
  String get name => 'run';

  @override
  String get description => 'Run a custom command on affected packages.';

  @override
  String get invocation => 'affected run -- <command>';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final failFast = argResults!['fail-fast'] as bool;
    final args = argResults!.rest;
    final logger = CliLogger();

    if (args.isEmpty) {
      logger
        ..error('Please specify a command to run.')
        ..info('')
        ..info('Usage: affected run -- <command>')
        ..info('')
        ..info('Examples:')
        ..info('  affected run -- "flutter test --coverage"')
        ..info('  affected run -- "dart format --set-exit-if-changed ."');
      return 64; // EX_USAGE
    }

    final commandString = args.join(' ');

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
        ..info('Running: $commandString');

      final exitCode = await service.runInPackages(
        packages: affectedPackages.toList(),
        commandString: commandString,
        failFast: failFast,
      );

      return exitCode;
    } on Exception catch (e) {
      logger.error('Failed to run command: $e');
      return 1;
    }
  }
}
