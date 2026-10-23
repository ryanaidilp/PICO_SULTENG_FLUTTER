import 'package:args/command_runner.dart';
import 'package:host_registry_generator/src/commands/host_registry_command.dart';
import 'package:host_registry_generator/src/commands/test_harness_command.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Parent command for code-generation operations that regenerate
/// marker-bounded regions of hand-written files from declarative sources.
///
/// Usage:
/// ```bash
/// monorepo_toolkit generate host-registry
/// monorepo_toolkit generate test-harness
/// ```
class GenerateCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [GenerateCommand].
  this {
    addSubcommand(HostRegistryCommand(logger: logger));
    addSubcommand(TestHarnessCommand(logger: logger));
  }

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Regenerate marker-bounded, machine-managed regions of hand-written '
      'files.';
}
