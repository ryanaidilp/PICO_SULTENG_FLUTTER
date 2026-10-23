import 'package:flutter/foundation.dart';

/// Reports a fatal crash.
///
/// In debug mode, prints to console. In production, bootstrap.dart wires
/// the actual monitoring call via GetIt after DI is initialised, so this
/// function serves as a lightweight fallback surface point.
///
/// Safe to call at any point in the app lifecycle — never throws.
void safeReportFatalCrash(Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint('[crash] fatal: $error\n$stackTrace');
  }
}

/// Reports a Flutter framework error.
///
/// Silently drops localization-delegate errors (CupertinoLocalizations /
/// localization delegates) which are spurious and cannot be acted on.
///
/// Safe to call at any point in the app lifecycle — never throws.
void safeReportFlutterFatalCrash(FlutterErrorDetails details) {
  if (kDebugMode) {
    final exceptionStr = details.exception.toString();
    final isLocalizationError =
        exceptionStr.contains('CupertinoLocalizations') ||
        exceptionStr.contains('localization delegates');
    if (isLocalizationError) return;

    FlutterError.dumpErrorToConsole(details);
  }
}

/// Reports a non-fatal error.
///
/// Safe to call at any point in the app lifecycle — never throws.
void safeReportNonFatalCrash(Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint('[crash] non-fatal: $error\n$stackTrace');
  }
}
