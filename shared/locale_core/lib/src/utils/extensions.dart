import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';

/// Localization-related extensions on [BuildContext].
extension LocaleExtension on BuildContext {
  /// The thousand separator for the current locale.
  String get thousandSeparator => switch (LocaleSettings.currentLocale) {
    PicoLocale.id => '.',
    PicoLocale.en => ',',
  };

  /// The decimal separator for the current locale.
  String get decimalSeparator => switch (LocaleSettings.currentLocale) {
    PicoLocale.id => ',',
    PicoLocale.en => '.',
  };
}
