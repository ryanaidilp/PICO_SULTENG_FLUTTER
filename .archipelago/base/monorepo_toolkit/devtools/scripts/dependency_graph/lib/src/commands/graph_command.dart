import 'package:args/command_runner.dart';
import 'package:dependency_graph/src/commands/cycles_command.dart';
import 'package:dependency_graph/src/commands/stats_command.dart';
import 'package:dependency_graph/src/commands/validate_command.dart';
import 'package:dependency_graph/src/commands/visualize_command.dart';

/// Parent command for dependency graph operations.
class GraphCommand() extends Command<int> {
  /// Creates a new [GraphCommand].
  this {
    addSubcommand(VisualizeCommand());
    addSubcommand(StatsCommand());
    addSubcommand(CyclesCommand());
    addSubcommand(ValidateCommand());
  }

  @override
  String get name => 'graph';

  @override
  String get description =>
      'Visualize and analyze dependency relationships in the workspace.';
}
