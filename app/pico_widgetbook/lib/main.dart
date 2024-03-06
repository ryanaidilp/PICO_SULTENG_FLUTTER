import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_widgetbook/app.dart';
import 'package:pico_widgetbook/widgetbook_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    return runApp(const WidgetbookApp());
  }

  if (Platform.isAndroid || Platform.isIOS) {
    return runApp(const App());
  }

  return runApp(const WidgetbookApp());
}
