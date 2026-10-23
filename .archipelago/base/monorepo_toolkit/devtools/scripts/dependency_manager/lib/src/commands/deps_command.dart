import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/commands/add_dependency_command.dart';
import 'package:dependency_manager/src/commands/add_external_dependency_command.dart';
import 'package:dependency_manager/src/commands/add_internal_dependency_command.dart';
import 'package:dependency_manager/src/commands/deps_align_command.dart';
import 'package:dependency_manager/src/commands/deps_check_command.dart';
import 'package:dependency_manager/src/commands/deps_diagnose_command.dart';
import 'package:dependency_manager/src/commands/remove_dependency_command.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// A command to manage shared dependencies in the monorepo.
///
/// Usage:
/// ```bash
/// monorepo_toolkit deps add <package_name>
/// monorepo_toolkit deps remove <package_name>
/// monorepo_toolkit deps internal <source> <target>
/// monorepo_toolkit deps external <target> <dependency> [version]
/// monorepo_toolkit deps check
/// monorepo_toolkit deps align <package> [constraint]
/// monorepo_toolkit deps diagnose [--write-overrides]
/// ```
class DepsCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsCommand].
  this {
    addSubcommand(DepsAddCommand(logger: logger));
    addSubcommand(DepsAlignCommand(logger: logger));
    addSubcommand(DepsCheckCommand(logger: logger));
    addSubcommand(DepsDiagnoseCommand(logger: logger));
    addSubcommand(DepsExternalCommand(logger: logger));
    addSubcommand(DepsInternalCommand(logger: logger));
    addSubcommand(DepsRemoveCommand(logger: logger));
  }

  @override
  String get name => 'deps';

  @override
  String get description => 'Manage shared dependencies in the monorepo.';
}
