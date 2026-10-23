import 'package:dependencies/di.dart';
import 'package:logger/logger.dart';

/// Module for registering core infrastructure dependencies.
@module
abstract class RegisterModule() {
  /// Provides a configured Logger instance.
  @lazySingleton
  Logger get logger => Logger(
    printer: PrettyPrinter(
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
}
