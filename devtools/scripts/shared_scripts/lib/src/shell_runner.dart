import 'dart:io';

/// Utility for running shell commands with output capture.
///
/// Provides static methods for executing shell commands, with
/// convenience wrappers for `dart` and `flutter` executables.
class ShellRunner() {
  /// Runs a shell command and returns its [ProcessResult].
  ///
  /// The [command] is split on spaces and executed as a process.
  /// Set [verbose] to `true` to print the command and its output.
  ///
  /// ```dart
  /// final result = await ShellRunner.run(
  ///   'flutter pub get',
  ///   workingDirectory: '/path/to/package',
  /// );
  /// ```
  static Future<ProcessResult> run(
    String command, {
    String? workingDirectory,
    bool verbose = false,
  }) async {
    final parts = command.split(' ');
    final executable = parts.first;
    final args = parts.skip(1).toList();

    if (verbose) {
      stdout.writeln('\x1B[2m\$ $command\x1B[0m');
    }

    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    if (verbose) {
      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      if (out.isNotEmpty) stdout.writeln(out);
      if (err.isNotEmpty) stderr.writeln(err);
    }

    return result;
  }

  /// Runs a `dart` command with the given [args].
  ///
  /// ```dart
  /// final result = await ShellRunner.runDart(
  ///   ['pub', 'get'],
  ///   workingDirectory: '/path/to/package',
  /// );
  /// ```
  static Future<ProcessResult> runDart(
    List<String> args, {
    String? workingDirectory,
    bool verbose = false,
  }) => run(
    'dart ${args.join(' ')}',
    workingDirectory: workingDirectory,
    verbose: verbose,
  );

  /// Runs a `flutter` command with the given [args].
  ///
  /// ```dart
  /// final result = await ShellRunner.runFlutter(
  ///   ['test', '--coverage'],
  ///   verbose: true,
  /// );
  /// ```
  static Future<ProcessResult> runFlutter(
    List<String> args, {
    String? workingDirectory,
    bool verbose = false,
  }) => run(
    'flutter ${args.join(' ')}',
    workingDirectory: workingDirectory,
    verbose: verbose,
  );
}
