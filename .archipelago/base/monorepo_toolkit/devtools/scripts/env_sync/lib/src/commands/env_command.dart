import 'package:args/command_runner.dart';
import 'package:env_sync/src/commands/env_add_command.dart';
import 'package:env_sync/src/commands/env_init_command.dart';
import 'package:env_sync/src/commands/env_switch_command.dart';
import 'package:env_sync/src/commands/env_sync_command.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// A command to manage environment configuration in shared/app_config.
///
/// Usage:
/// ```bash
/// monorepo_toolkit env init
/// monorepo_toolkit env add API_BASE_URL
/// monorepo_toolkit env sync
/// monorepo_toolkit env switch development
/// ```
class EnvCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [EnvCommand].
  this {
    addSubcommand(EnvInitCommand(logger: logger));
    addSubcommand(EnvAddCommand(logger: logger));
    addSubcommand(EnvSyncCommand(logger: logger));
    addSubcommand(EnvSwitchCommand(logger: logger));
  }

  @override
  String get name => 'env';

  @override
  String get description =>
      'Manage environment configuration in shared/app_config.';
}
