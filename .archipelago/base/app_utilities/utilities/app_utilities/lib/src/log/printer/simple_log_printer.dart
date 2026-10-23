import 'package:logger/logger.dart';

/// A minimal [LogPrinter] that outputs a single line per log event.
///
/// Format: `<emoji> <message>`
class SimpleLogPrinter() extends LogPrinter {
  /// Creates a [SimpleLogPrinter].
  this;

  @override
  List<String> log(LogEvent event) => [
    '${PrettyPrinter.defaultLevelEmojis[event.level]} ${event.message}',
  ];
}
