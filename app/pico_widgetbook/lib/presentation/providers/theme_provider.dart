import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDark = false;
    themeMode =
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
  late bool _isDark;
  late ThemeMode themeMode;
  bool get isDark => _isDark;

  set isDark(bool value) {
    _isDark = value;
    themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
