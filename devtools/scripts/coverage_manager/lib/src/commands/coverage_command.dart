import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/commands/check_command.dart';
import 'package:coverage_manager/src/commands/combine_command.dart';
import 'package:coverage_manager/src/commands/full_command.dart';
import 'package:coverage_manager/src/commands/init_command.dart';
import 'package:coverage_manager/src/commands/run_command.dart';

/// Parent command for coverage management operations.
class CoverageCommand() extends Command<int> {
  /// Creates a new [CoverageCommand].
  this {
    addSubcommand(InitCommand());
    addSubcommand(RunCommand());
    addSubcommand(CombineCommand());
    addSubcommand(CheckCommand());
    addSubcommand(FullCommand());
  }

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Test coverage pipeline with configurable thresholds.';
}
