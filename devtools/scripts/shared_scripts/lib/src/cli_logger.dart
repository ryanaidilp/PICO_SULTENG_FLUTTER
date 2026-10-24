import 'dart:io';

/// ANSI color codes for terminal output.
class _Ansi() {
  static const reset = '\x1B[0m';
  static const dim = '\x1B[2m';

  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const cyan = '\x1B[36m';

  static const brightRed = '\x1B[91m';
  static const brightGreen = '\x1B[92m';
  static const brightYellow = '\x1B[93m';
  static const brightBlue = '\x1B[94m';
  static const brightCyan = '\x1B[96m';
}

/// Icons for log messages.
class _Icons() {
  static const success = '\u2713';
  static const failure = '\u2717';
  static const warning = '\u26A0';
  static const info = '\u2139';
  static const running = '\u25CF';
}

/// A formatted logger for CLI output with ANSI colors.
///
/// Supports info, success, warning, error, verbose, and progress
/// messages. Colors are enabled by default and can be disabled.
///
/// ```dart
/// final logger = CliLogger(verbose: true);
/// logger.info('Processing files...');
/// logger.success('Done!');
/// ```
class CliLogger({
  /// Whether verbose messages are shown.
  final bool verbose = false,

  /// Whether ANSI colors are used.
  final bool useColors = true,
  StringSink? output,
}) {
  /// Creates a new [CliLogger].
  ///
  /// Set [verbose] to `true` to enable verbose output.
  /// Set [useColors] to `false` to disable ANSI colors.
  this;

  /// Output sink (defaults to stdout).
  final StringSink _output = output ?? stdout;

  /// Logs an informational message.
  ///
  /// Example output: `i Processing files...`
  void info(String message) {
    final icon = _color(_Icons.info, _Ansi.brightBlue);
    _output.writeln('$icon ${_color(message, _Ansi.blue)}');
  }

  /// Logs a success message.
  ///
  /// Example output: `v Operation completed`
  void success(String message) {
    final icon = _color(_Icons.success, _Ansi.brightGreen);
    _output.writeln('$icon ${_color(message, _Ansi.green)}');
  }

  /// Logs a warning message.
  ///
  /// Example output: `! Something looks off`
  void warning(String message) {
    final icon = _color(_Icons.warning, _Ansi.brightYellow);
    _output.writeln('$icon ${_color(message, _Ansi.yellow)}');
  }

  /// Logs an error message to stderr.
  ///
  /// Example output: `x Something failed`
  void error(String message) {
    final icon = _color(_Icons.failure, _Ansi.brightRed);
    stderr.writeln('$icon ${_color(message, _Ansi.red)}');
  }

  /// Logs a verbose message (only printed when [verbose] is `true`).
  void verbose_(String message) {
    if (!verbose) return;
    _output.writeln(_color('  $message', _Ansi.dim));
  }

  /// Logs a progress/running indicator.
  ///
  /// Example output: `* Compiling...`
  void progress(String message) {
    final icon = _color(_Icons.running, _Ansi.brightCyan);
    _output.writeln('$icon ${_color(message, _Ansi.cyan)}');
  }

  /// Applies ANSI color to [text] if colors are enabled.
  String _color(String text, String colorCode) =>
      useColors ? '$colorCode$text${_Ansi.reset}' : text;
}
