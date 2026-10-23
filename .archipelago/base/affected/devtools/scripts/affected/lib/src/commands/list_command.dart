import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to list packages affected by git changes.
class ListCommand() extends Command<int> {
  /// Creates a new [ListCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format.',
        allowed: ['pretty', 'plain'],
        defaultsTo: 'pretty',
      )
      ..addFlag(
        'json',
        abbr: 'j',
        help: 'Output as JSON array (for GitHub Actions matrix).',
        negatable: false,
      );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List packages affected by git changes.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final format = argResults!['format'] as String;
    final isJson = argResults!['json'] as bool;
    final isPlain = isJson || format == 'plain';
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
        if (!isPlain) {
          logger.info('No changes detected compared to $baseBranch.');
        }
        return 0;
      }

      final affectedPackages = service.getAffectedWithDependents(changedFiles);

      if (affectedPackages.isEmpty) {
        if (!isPlain) logger.info('No packages affected by the changes.');
        return 0;
      }

      final sorted = affectedPackages.toList()..sort();

      if (isJson) {
        // ignore: avoid_print - JSON output for GitHub Actions matrix
        print('[${sorted.map((p) => '"$p"').join(',')}]');
      } else if (isPlain) {
        // ignore: avoid_print - plain output for CI piping
        sorted.forEach(print);
      } else {
        logger
          ..info('Comparing HEAD with $baseBranch...')
          ..info('Found ${affectedPackages.length} affected package(s):');

        for (var i = 0; i < sorted.length; i++) {
          logger.info('  ${i + 1}. ${sorted[i]}');
        }
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to list affected packages: $e');
      return 1;
    }
  }
}
