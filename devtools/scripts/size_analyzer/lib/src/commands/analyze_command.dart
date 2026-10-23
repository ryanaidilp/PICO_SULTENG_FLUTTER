import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:size_analyzer/src/models/size_node.dart';
import 'package:size_analyzer/src/services/size_analyzer_service.dart';

class AnalyzeCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'json',
        abbr: 'j',
        help: 'Path to the Flutter --analyze-size JSON output file.',
        mandatory: true,
      )
      ..addOption(
        'baseline',
        abbr: 'b',
        help: 'Path to baseline JSON (relative to monorepo root) for diff.',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help:
            'Platform label (android, ios) forwarded to the metrics reporter.',
      )
      ..addOption(
        'top',
        help: 'Number of top packages to display.',
        defaultsTo: '20',
      );
  }

  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Parse Flutter --analyze-size JSON and show top size contributors.';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final rootPath = MonorepoFinder.requireRoot();
    final jsonPath = argResults!['json'] as String;
    final baselinePath = argResults?['baseline'] as String?;
    final platform = argResults?['platform'] as String?;
    final topN = int.tryParse(argResults!['top'] as String) ?? 20;

    final service = SizeAnalyzerService(rootPath: rootPath);

    logger.info('Analyzing size report: $jsonPath');
    final List<SizeNode> nodes;
    try {
      nodes = await service.analyzeJson(jsonPath, platform: platform);
    } catch (e) {
      logger.error('Failed to parse size JSON: $e');
      return 1;
    }

    logger.info('\nTop $topN packages by size:');
    for (final (i, node) in nodes.take(topN).indexed) {
      logger.info('  ${i + 1}. ${node.name}: ${node.formatted}');
    }

    if (baselinePath != null) {
      final baseline = service.loadBaseline(baselinePath);
      if (baseline.isEmpty) {
        logger.info('\nNo baseline at $baselinePath — skipping diff.');
      } else {
        final diffs = SizeAnalyzerService.diffBaseline(
          current: nodes,
          baseline: baseline,
        );
        if (diffs.isEmpty) {
          logger.success('\nNo size changes vs baseline.');
        } else {
          final increases = diffs.where((d) => d.isIncrease).toList();
          final decreases = diffs.where((d) => !d.isIncrease).toList();

          if (increases.isNotEmpty) {
            logger.error('\nSize increases vs baseline:');
            for (final d in increases.take(10)) {
              logger.error(
                '  ${d.name}: ${d.deltaFormatted}${d.isNew ? " (new)" : ""}',
              );
            }
          }
          if (decreases.isNotEmpty) {
            logger.info('\nSize decreases vs baseline:');
            for (final d in decreases.take(10)) {
              logger.info('  ${d.name}: ${d.deltaFormatted}');
            }
          }
        }
      }
    }

    return 0;
  }
}
