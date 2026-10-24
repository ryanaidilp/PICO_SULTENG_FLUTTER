import 'package:args/command_runner.dart';
import 'package:dependency_graph/src/services/graph_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to show dependency graph statistics.
class StatsCommand() extends Command<int> {
  @override
  String get name => 'stats';

  @override
  String get description => 'Show statistics about the dependency graph.';

  @override
  Future<int> run() async {
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      const service = GraphService();
      final graph = service.analyze(rootPath);
      final stats = graph.stats;

      logger
        ..info('')
        ..info('Dependency Graph Statistics')
        ..info('')
        ..info('  Total packages:      ${stats.totalPackages}')
        ..info('  Total dependencies:  ${stats.totalEdges}')
        ..info('  Flutter packages:    ${stats.flutterPackages}')
        ..info('  Dart packages:       ${stats.dartPackages}')
        ..info('')
        ..info('Structure')
        ..info('')
        ..info('  Root packages:       ${stats.rootPackages}')
        ..info('  Leaf packages:       ${stats.leafPackages}')
        ..info('  Max dependencies:    ${stats.maxDependencies}')
        ..info(
          '  Avg dependencies:    '
          '${stats.avgDependencies.toStringAsFixed(2)}',
        )
        ..info('');

      // Most depended-on packages.
      final dependentCounts = <String, int>{};
      for (final edge in graph.edges) {
        dependentCounts[edge.to] = (dependentCounts[edge.to] ?? 0) + 1;
      }
      final sortedByDependents = dependentCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedByDependents.isNotEmpty) {
        logger.info('Most Depended On:');
        for (final entry in sortedByDependents.take(5)) {
          logger.info('  ${entry.key}: ${entry.value} dependents');
        }
        logger.info('');
      }

      // Most dependent packages.
      final sorted = graph.nodes.toList()
        ..sort((a, b) => b.dependencyCount.compareTo(a.dependencyCount));
      if (sorted.isNotEmpty) {
        logger.info('Most Dependencies:');
        for (final node in sorted.take(5)) {
          logger.info('  ${node.name}: ${node.dependencyCount} dependencies');
        }
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to generate stats: $e');
      return 1;
    }
  }
}
