import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Font family for test environments that uses locally loaded fonts.
///
/// Use this to avoid Google Fonts network fetching in golden tests.
/// The font names must match those declared in `test/fonts/` via pubspec.yaml.
const testFontFamily = PicoFontFamily(
  bodyFontFamily: 'Plus Jakarta Sans',
  headingFontFamily: 'Plus Jakarta Sans',
  monoFontFamily: 'JetBrains Mono',
);

/// Test wrapper that provides app theming for golden tests.
///
/// Wraps widgets with [MaterialApp] and applies either light or dark theme
/// using [PicoTheme].
///
/// By default, uses [testFontFamily] to avoid Google Fonts network fetching
/// and ensure text renders correctly in golden tests.
class const AppComponentTestWrapper({
  /// The widget to wrap with theme.
  required final Widget child,

  /// Whether to use dark mode theme.
  final bool isDarkMode = false,

  /// Optional custom font family.
  ///
  /// Defaults to [testFontFamily] which uses locally loaded fonts
  /// from `test/fonts/` to avoid Google Fonts network fetching.
  final PicoFontFamily fontFamily = testFontFamily,
  super.key,
}) extends StatelessWidget {
  /// Creates an [AppComponentTestWrapper].
  this;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pico UI Kit Test',
    theme: isDarkMode
        ? PicoTheme.dark(fontFamily: fontFamily)
        : PicoTheme.light(fontFamily: fontFamily),
    debugShowCheckedModeBanner: false,
    home: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isDarkMode', isDarkMode))
      ..add(DiagnosticsProperty<PicoFontFamily>('fontFamily', fontFamily));
  }
}

/// Convenience function to build a themed test wrapper.
///
/// Provides backward compatibility with foundation tests that use a
/// function-based approach.
Widget buildTestWrapper({
  required Widget child,
  Brightness brightness = Brightness.light,
}) => AppComponentTestWrapper(
  isDarkMode: brightness == Brightness.dark,
  child: child,
);
