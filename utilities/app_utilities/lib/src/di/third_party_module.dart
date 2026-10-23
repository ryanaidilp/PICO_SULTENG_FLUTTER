import 'package:app_utilities/src/log/filter/release_log_filter.dart';
import 'package:app_utilities/src/log/printer/simple_log_printer.dart';
import 'package:dependencies/di.dart';
import 'package:logger/logger.dart';

/// Injectable module that provides third-party dependencies.
@module
abstract class ThirdPartyModule() {
  /// Provides a [Logger] instance configured with [ReleaseLogFilter]
  /// and [SimpleLogPrinter].
  Logger get logger =>
      Logger(filter: ReleaseLogFilter(), printer: SimpleLogPrinter());
}
