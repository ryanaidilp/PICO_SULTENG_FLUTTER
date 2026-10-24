import 'package:args/command_runner.dart';
import 'package:asset_generator/src/commands/generate_command.dart';

/// Parent command for asset generation operations.
class AssetGenCommand() extends Command<int> {
  /// Creates a new [AssetGenCommand].
  this {
    addSubcommand(GenerateCommand());
  }

  @override
  String get name => 'asset-gen';

  @override
  String get description =>
      'Generate type-safe asset enums from directory structure.';
}
