import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/commands/add_command.dart';
import 'package:flavor_manager/src/commands/generate_command.dart';
import 'package:flavor_manager/src/commands/list_apps_command.dart';
import 'package:flavor_manager/src/commands/list_command.dart';
import 'package:flavor_manager/src/commands/sync_command.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// A command to manage app flavors using flutter_flavorizr.
///
/// Usage:
/// ```bash
/// monorepo_toolkit flavor list-apps
/// monorepo_toolkit flavor list --app template_app
/// monorepo_toolkit flavor add --app template_app --name qa
/// monorepo_toolkit flavor generate --app template_app
/// monorepo_toolkit flavor sync --init
/// ```
class FlavorCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [FlavorCommand].
  this {
    addSubcommand(ListAppsCommand(logger: logger));
    addSubcommand(ListFlavorsCommand(logger: logger));
    addSubcommand(AddFlavorCommand(logger: logger));
    addSubcommand(GenerateCommand(logger: logger));
    addSubcommand(SyncCommand(logger: logger));
  }

  @override
  String get name => 'flavor';

  @override
  String get description => 'Manage app flavors using flutter_flavorizr.';
}
