import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:size_analyzer/src/models/size_node.dart';
import 'package:size_analyzer/src/services/size_analyzer_service.dart';

class UpdateBaselineCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'json',
        abbr: 'j',
        help: 'Path to the Flutter --analyze-size JSON output file.',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output baseline path relative to monorepo root.',
        mandatory: true,
      );
  }

  @override
  String get name => 'update-baseline';

  @override
  String get description =>
      'Update the size baseline from a fresh build (run on develop merge).';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final rootPath = MonorepoFinder.requireRoot();
    final jsonPath = argResults!['json'] as String;
    final outputPath = argResults!['output'] as String;

    final service = SizeAnalyzerService(rootPath: rootPath);

    logger.info('Updating size baseline from $jsonPath...');
    final List<SizeNode> nodes;
    try {
      nodes = await service.analyzeJson(jsonPath);
    } catch (e) {
      logger.error('Failed to parse size JSON: $e');
      return 1;
    }

    service.updateBaseline(nodes, outputPath);
    logger.success('Baseline updated: $outputPath (${nodes.length} packages)');
    return 0;
  }
}
