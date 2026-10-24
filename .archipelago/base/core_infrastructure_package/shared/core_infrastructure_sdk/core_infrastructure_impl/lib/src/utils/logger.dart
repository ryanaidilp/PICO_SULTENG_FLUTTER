import 'package:core_infrastructure_impl/src/di/injector.dart';
import 'package:logger/logger.dart';

/// Get the configured logger instance from dependency injection.
Logger get appLogger => getIt<Logger>();

/// Extension methods for easier logging.
extension LoggerX on Object {
  /// Log debug message.
  void logDebug(dynamic message) => appLogger.d(message);

  /// Log info message.
  void logInfo(dynamic message) => appLogger.i(message);

  /// Log warning message.
  void logWarning(dynamic message) => appLogger.w(message);

  /// Log error message.
  void logError(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.e(message, error: error, stackTrace: stackTrace);
  }
}
