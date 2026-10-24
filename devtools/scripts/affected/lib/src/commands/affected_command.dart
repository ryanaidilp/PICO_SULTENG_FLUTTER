import 'package:affected/src/commands/analyze_command.dart';
import 'package:affected/src/commands/build_command.dart';
import 'package:affected/src/commands/devtool_command.dart';
import 'package:affected/src/commands/fix_check_command.dart';
import 'package:affected/src/commands/format_command.dart';
import 'package:affected/src/commands/golden_command.dart';
import 'package:affected/src/commands/license_command.dart';
import 'package:affected/src/commands/list_command.dart';
import 'package:affected/src/commands/run_command.dart';
import 'package:affected/src/commands/test_command.dart';
import 'package:args/command_runner.dart';

/// Parent command for running commands on affected packages.
class AffectedCommand() extends Command<int> {
  /// Creates a new [AffectedCommand].
  this {
    addSubcommand(ListCommand());
    addSubcommand(FormatCommand());
    addSubcommand(FixCheckCommand());
    addSubcommand(AnalyzeCommand());
    addSubcommand(TestCommand());
    addSubcommand(GoldenCommand());
    addSubcommand(LicenseCommand());
    addSubcommand(BuildCommand());
    addSubcommand(DevtoolCommand());
    addSubcommand(RunCommand());
  }

  @override
  String get name => 'affected';

  @override
  String get description => 'Run commands on packages affected by git changes.';
}
