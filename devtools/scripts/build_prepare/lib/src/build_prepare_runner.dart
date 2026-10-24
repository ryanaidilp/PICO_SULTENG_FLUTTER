import 'package:args/command_runner.dart';
import 'package:build_prepare/src/build_prepare_command.dart';

/// Entry point runner for the build_prepare tool.
///
/// Encapsulates CLI parsing and execution logic so that
/// `monorepo_toolkit` (or any other host) can invoke build_prepare
/// without going through `bin/`.
///
/// Usage:
/// ```dart
/// final exitCode = await BuildPrepareRunner().run(['release']);
/// ```
class BuildPrepareRunner() {
  /// Creates a new [BuildPrepareRunner].
  this
    : _runner = CommandRunner<int>(
        'build-prepare',
        'Swap debug/release dependencies for build preparation.',
      )..addCommand(BuildPrepareCommand());

  final CommandRunner<int> _runner;

  /// Runs the build_prepare tool with the given [args].
  ///
  /// Returns an exit code (0 for success, non-zero for failure).
  Future<int> run(List<String> args) async {
    // Prepend the command name since CommandRunner expects it
    final result = await _runner.run(['build-prepare', ...args]);
    return result ?? 0;
  }
}
