import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// The in-app boot screen: the legacy PICO logo on the themed background with
/// a progress ring under it, the same picture as the native splash so the
/// hand-over shows no jump. It needs no `Theme` (it runs before `MaterialApp`),
/// so the light or dark ground follows the OS brightness.
class PicoBootScreen extends StatelessWidget {
  /// Creates the boot screen.
  const PicoBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return ColoredBox(
      color: dark ? PicoBrandPalette.paperDark : PicoBrandPalette.paperLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'PICO SulTeng',
              child: ExcludeSemantics(
                child: SvgPicture.asset(
                  'assets/logo/pico-logo.svg',
                  package: 'pico_ui_kit',
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: dark
                    ? PicoBrandPalette.indigoDark
                    : PicoBrandPalette.indigoLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
