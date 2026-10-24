import 'package:dependencies/di.dart';
import 'package:logger/logger.dart';

/// Log message type for severity level.
enum LogType() {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// A wrapper around [Logger] for centralized logging.
///
/// Provides structured logging with convenience methods [d], [i], [w], [e],
/// [t], and [f] for debug, info, warning, error, trace, and fatal levels.
///
/// Also supports [console] for enum-based level selection and [consoleLazy]
/// for deferred message construction to avoid allocation in release builds.
@LazySingleton()
class const Log(final Logger _logger) {
  /// Creates a [Log] instance wrapping the given [Logger].
  this;

  /// Logs a trace-level message.
  void t(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  /// Logs a debug-level message.
  void d(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  /// Logs an info-level message.
  void i(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  /// Logs a warning-level message.
  void w(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Logs an error-level message.
  void e(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Logs a fatal-level message.
  void f(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);

  /// Logs a message with optional error and stack trace.
  void console(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    LogType type = LogType.debug,
  }) {
    switch (type) {
      case LogType.verbose:
        _logger.t(message, error: error, stackTrace: stackTrace);
      case LogType.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
      case LogType.info:
        _logger.i(message, error: error, stackTrace: stackTrace);
      case LogType.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
      case LogType.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
      case LogType.fatal:
        _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Logs a lazily-evaluated message.
  ///
  /// The [messageBuilder] is only called if logging is enabled (debug mode).
  /// This avoids string allocation overhead in release builds.
  void consoleLazy(
    String Function() messageBuilder, {
    dynamic error,
    StackTrace? stackTrace,
    LogType type = LogType.debug,
  }) {
    switch (type) {
      case LogType.verbose:
        _logger.t(messageBuilder(), error: error, stackTrace: stackTrace);
      case LogType.debug:
        _logger.d(messageBuilder(), error: error, stackTrace: stackTrace);
      case LogType.info:
        _logger.i(messageBuilder(), error: error, stackTrace: stackTrace);
      case LogType.warning:
        _logger.w(messageBuilder(), error: error, stackTrace: stackTrace);
      case LogType.error:
        _logger.e(messageBuilder(), error: error, stackTrace: stackTrace);
      case LogType.fatal:
        _logger.f(messageBuilder(), error: error, stackTrace: stackTrace);
    }
  }
}
