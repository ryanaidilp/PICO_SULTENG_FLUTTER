import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// The shared illustration frame: a soft round tint with a thin outline (the
/// first design drew a woven ring and a crimson knot; the original look has
/// neither, so [knot] is accepted and ignored).
class PicoWovenPlate extends StatelessWidget {
  /// Creates a plate around [child].
  const new({
    required this.child,
    this.knot = false,
    this.size = 200,
    super.key,
  });

  /// Content, drawn inside the disc.
  final Widget child;

  /// Ignored. Kept for the callers of the first design.
  final bool knot;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? PicoBrandPalette.tintDark : PicoBrandPalette.tintLight,
          border: Border.all(
            color: dark
                ? PicoBrandPalette.lineDark
                : PicoBrandPalette.lineLight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: Center(child: child),
        ),
      ),
    );
  }
}
