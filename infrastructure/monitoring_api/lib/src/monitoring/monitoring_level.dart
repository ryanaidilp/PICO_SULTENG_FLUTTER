/// Log level for monitoring messages.
///
/// Ordered from least to most severe:
/// - [debug] - Detailed information for debugging
/// - [info] - General informational messages
/// - [warning] - Warning conditions
/// - [error] - Error conditions
/// - [fatal] - Critical failures requiring immediate attention
enum MonitoringLevel() {
  /// Detailed information for debugging purposes.
  debug,

  /// General informational messages about app operation.
  info,

  /// Warning conditions that should be reviewed.
  warning,

  /// Error conditions that affected operation.
  error,

  /// Critical failures requiring immediate attention.
  fatal,
}
