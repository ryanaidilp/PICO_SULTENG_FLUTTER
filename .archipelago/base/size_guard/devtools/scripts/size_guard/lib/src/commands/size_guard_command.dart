import 'package:args/command_runner.dart';
import 'package:size_guard/src/commands/check_command.dart';

/// Parent command for size guard operations.
class SizeGuardCommand() extends Command<int> {
  /// Creates a new [SizeGuardCommand].
  this {
    addSubcommand(CheckCommand());
  }

  @override
  String get name => 'size-guard';

  @override
  String get description =>
      'Enforce file size limits by scanning for files exceeding thresholds.';
}
