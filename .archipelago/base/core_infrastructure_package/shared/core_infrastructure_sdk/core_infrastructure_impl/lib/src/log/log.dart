import 'package:core_infrastructure_api/core_infrastructure_api.dart';
import 'package:dependencies/di.dart';
import 'package:logger/logger.dart';

export 'filter/filter.dart';
export 'printer/printer.dart';

@LazySingleton(as: Log)
class const LogImpl({required final Logger _logger}) implements Log {
  @override
  Future<void> console(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    LogType type = LogType.debug,
  }) async {
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
}
