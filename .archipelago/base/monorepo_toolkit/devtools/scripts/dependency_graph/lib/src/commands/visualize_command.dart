import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dependency_graph/src/services/graph_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to visualize the dependency graph.
class VisualizeCommand() extends Command<int> {
  /// Creates a new [VisualizeCommand].
  this {
    argParser
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format for the graph.',
        allowed: ['text', 'dot', 'mermaid', 'json'],
        defaultsTo: 'text',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path. If not specified, prints to stdout.',
      );
  }

  @override
  String get name => 'visualize';

  @override
  String get description => 'Generate a visualization of the dependency graph.';

  @override
  Future<int> run() async {
    final format = argResults!['format'] as String;
    final outputPath = argResults!['output'] as String?;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      const service = GraphService();
      final graph = service.analyze(rootPath);

      logger.info('Found ${graph.nodes.length} packages');

      final output = switch (format) {
        'dot' => graph.toDot(),
        'mermaid' => graph.toMermaid(),
        'json' => graph.toJson(),
        _ => graph.toText(),
      };

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(output);
        logger.success('Graph written to $outputPath');
      } else {
        // ignore: avoid_print - stdout output when no file path specified
        print(output);
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to visualize graph: $e');
      return 1;
    }
  }
}
