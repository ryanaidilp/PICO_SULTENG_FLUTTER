import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A [LogFilter] that only allows logging in debug mode.
///
/// Uses [kDebugMode] to suppress all logs in release and profile builds.
class ReleaseLogFilter() extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => kDebugMode;
}
