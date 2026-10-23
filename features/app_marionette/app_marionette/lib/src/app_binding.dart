import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Installs the app's [WidgetsBinding]. Call it first in `main()`, before
/// anything that touches the binding (Firebase, Sentry, plugins): Flutter
/// allows one binding per process.
///
/// Debug builds get [MarionetteBinding], so an AI agent can drive the app
/// through the `marionette_mcp` server. Release and profile builds never
/// contain this package: `build-prepare --mode release|profile` swaps it for
/// `app_marionette_noop`. The `kDebugMode` check is a second layer.
///
/// [isInteractiveElement] marks design-system controls as tappable, on top
/// of the Material widgets Marionette already knows.
WidgetsBinding ensureAppBinding({
  bool Function(Element element)? isInteractiveElement,
}) {
  if (kDebugMode &&
      useMarionette(
        environment: Platform.environment,
        bindingInstalled: _bindingInstalled(),
      )) {
    // The app logs through package:logger; forward it to `get_logs`.
    final logs = PrintLogCollector();
    Logger.addOutputListener((event) => logs.addLog(event.lines.join('\n')));
    return MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(
        isInteractiveElement: isInteractiveElement,
        logCollector: logs,
      ),
    );
  }
  return WidgetsFlutterBinding.ensureInitialized();
}

/// Whether a debug build should install [MarionetteBinding].
///
/// Not under `flutter test` (`FLUTTER_TEST`), and not when a binding already
/// exists: integration and Patrol tests install theirs before calling
/// `main()`, and [MarionetteBinding.ensureInitialized] throws on a second
/// binding.
@visibleForTesting
bool useMarionette({
  required Map<String, String> environment,
  required bool bindingInstalled,
}) => !environment.containsKey('FLUTTER_TEST') && !bindingInstalled;

bool _bindingInstalled() {
  try {
    WidgetsBinding.instance;
    return true;
  } on Object {
    return false;
  }
}
