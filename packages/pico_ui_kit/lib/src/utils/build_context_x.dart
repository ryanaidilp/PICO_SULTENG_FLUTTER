import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/theme/pico_color_theme.dart';

extension BuildContextX on BuildContext {
  ThemeExtension<PicoColorTheme> get _colorThemeExtension =>
      Theme.of(this).extension<PicoColorTheme>()!;

  PicoColorTheme get picoColors => _colorThemeExtension as PicoColorTheme;
}
