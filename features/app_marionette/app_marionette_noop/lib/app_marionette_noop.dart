/// Release and profile twin of `app_marionette`: same public API, plain
/// [WidgetsFlutterBinding], no Marionette dependency.
library;

import 'package:flutter/widgets.dart';

/// Installs the plain [WidgetsFlutterBinding]. [isInteractiveElement] is
/// accepted so the host compiles unchanged after the swap, and ignored.
WidgetsBinding ensureAppBinding({
  bool Function(Element element)? isInteractiveElement,
}) => WidgetsFlutterBinding.ensureInitialized();
