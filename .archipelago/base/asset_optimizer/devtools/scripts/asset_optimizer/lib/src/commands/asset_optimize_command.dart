import 'package:args/command_runner.dart';
import 'package:asset_optimizer/src/commands/optimize_command.dart';

/// Parent command for asset optimization operations.
class AssetsCommand() extends Command<int> {
  /// Creates a new [AssetsCommand].
  this {
    addSubcommand(OptimizeCommand());
  }

  @override
  String get name => 'assets';

  @override
  String get description => 'Optimize image assets (SVG, PNG, JPEG).';
}
