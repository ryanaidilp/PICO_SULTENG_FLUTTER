import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:workspace_setup/src/commands/fix_resolution_command.dart';
import 'package:workspace_setup/src/commands/setup_command.dart';
import 'package:workspace_setup/src/commands/validate_command.dart';

/// A command to manage workspace configuration in the monorepo.
///
/// Subcommands:
/// - `setup`          — One-time migration from explicit list to glob patterns.
/// - `fix-resolution` — Adds `resolution: workspace` to packages missing it.
/// - `validate`       — Validates workspace health (resolution flags, override
///                      conflicts).
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit workspace setup
/// dart run monorepo_toolkit workspace fix-resolution
/// dart run monorepo_toolkit workspace validate
/// ```
class WorkspaceCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [WorkspaceCommand].
  this {
    addSubcommand(SetupCommand(logger: logger));
    addSubcommand(FixResolutionCommand(logger: logger));
    addSubcommand(ValidateCommand(logger: logger));
  }

  @override
  String get name => 'workspace';

  @override
  String get description =>
      'Manage Dart workspace configuration in the monorepo.';
}
