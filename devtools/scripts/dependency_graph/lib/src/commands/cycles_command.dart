import 'package:args/command_runner.dart';
import 'package:dependency_graph/src/services/graph_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to detect circular dependencies in the workspace.
class CyclesCommand() extends Command<int> {
  /// Creates a new [CyclesCommand].
  this {
    argParser.addFlag(
      'fail',
      help: 'Exit with non-zero code if cycles are found.',
      defaultsTo: true,
    );
  }

  @override
  String get name => 'cycles';

  @override
  String get description => 'Detect circular dependencies in the workspace.';

  @override
  Future<int> run() async {
    final failOnCycles = argResults!['fail'] as bool;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      const service = GraphService();
      final graph = service.analyze(rootPath);
      final cycles = graph.findCycles();

      if (cycles.isEmpty) {
        logger.success('No circular dependencies detected!');
        return 0;
      }

      logger.warning('Found ${cycles.length} circular dependency chain(s):');

      for (var i = 0; i < cycles.length; i++) {
        final cycle = cycles[i];
        logger.info('  ${i + 1}. ${cycle.join(' -> ')}');
      }

      logger.warning(
        'Circular dependencies can cause issues with build order '
        'and code organization.',
      );

      return failOnCycles ? 1 : 0;
    } on Exception catch (e) {
      logger.error('Failed to detect cycles: $e');
      return 1;
    }
  }
}
