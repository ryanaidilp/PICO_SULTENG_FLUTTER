import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The PICO wordmark in the colour set of the current theme. It is the app bar
/// title of the tab roots.
class PicoWordmark extends StatelessWidget {
  /// Creates the wordmark at [height]. [semanticLabel] names it for screen
  /// readers.
  const PicoWordmark({
    this.height = 24,
    this.semanticLabel = 'PICO',
    super.key,
  });

  /// Height in logical pixels.
  final double height;

  /// Screen reader label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      dark
          ? 'assets/logo/pico-wordmark-color-dark.svg'
          : 'assets/logo/pico-wordmark-color.svg',
      package: 'pico_ui_kit',
      height: height,
      semanticsLabel: semanticLabel,
    );
  }
}
