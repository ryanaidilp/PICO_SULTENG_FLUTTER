import 'package:core_infrastructure_api/core_infrastructure_api.dart';

export 'log_type.dart';

abstract class Log() {
  Future<void> console(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    LogType type = LogType.debug,
  });
}
