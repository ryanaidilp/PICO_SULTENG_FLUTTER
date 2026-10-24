import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run flutter test on affected packages.
class TestCommand() extends Command<int> {
  /// Creates a new [TestCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addFlag(
        'coverage',
        help: 'Collect coverage information.',
        negatable: false,
      )
      ..addFlag(
        'goldens',
        help: 'Include golden-tagged tests (excluded by default).',
        negatable: false,
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package failure.',
        defaultsTo: true,
      )
      ..addOption(
        'total-shards',
        help: 'Total number of shards for within-package test splitting.',
      )
      ..addOption(
        'shard-index',
        help: 'Zero-based index of this shard (requires --total-shards).',
      );
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run flutter test on affected packages.';

  /// `flutter test` exits 79 when a package has no tests to run.
  static const noTestsExitCode = 79;

  /// Builds the `flutter test` command line.
  static String buildCommand({
    bool coverage = false,
    bool goldens = false,
    String? totalShards,
    String? shardIndex,
  }) {
    final shards = totalShards != null
        ? ' --total-shards $totalShards --shard-index $shardIndex'
        : '';
    return 'flutter test'
        '${coverage ? ' --coverage' : ''}'
        '${goldens ? '' : ' --exclude-tags golden'}'
        '$shards';
  }

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final coverage = argResults!['coverage'] as bool;
    final goldens = argResults!['goldens'] as bool;
    final failFast = argResults!['fail-fast'] as bool;
    final totalShards = argResults!['total-shards'] as String?;
    final shardIndex = argResults!['shard-index'] as String?;
    final logger = CliLogger();

    if ((totalShards == null) != (shardIndex == null)) {
      logger.error('--total-shards and --shard-index must be used together.');
      return 1;
    }

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

      final command = buildCommand(
        coverage: coverage,
        goldens: goldens,
        totalShards: totalShards,
        shardIndex: shardIndex,
      );

      logger
        ..info('Comparing HEAD with $baseBranch...')
        ..info('Found ${affectedPackages.length} affected package(s)')
        ..info('Running: $command');

      final exitCode = await service.runInPackages(
        packages: affectedPackages.toList(),
        commandString: command,
        failFast: failFast,
        requiredDir: 'test',
        okExitCodes: const {0, noTestsExitCode},
      );

      return exitCode;
    } on Exception catch (e) {
      logger.error('Failed to run tests: $e');
      return 1;
    }
  }
}
