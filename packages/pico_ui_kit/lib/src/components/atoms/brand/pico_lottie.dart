import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// A brand Lottie by name (`pico-loading`, `pico-success`, ...). It recolours
/// the named layers for the theme. With animations disabled by the OS it shows
/// the static SVG and never builds a Lottie.
class PicoLottie extends StatelessWidget {
  /// Creates the animation.
  const new(
    this.name, {
    this.width,
    this.height,
    this.repeat = true,
    this.semanticLabel,
    super.key,
  });

  /// File stem, for example `pico-loading`.
  final String name;

  /// Width.
  final double? width;

  /// Height.
  final double? height;

  /// Loop the animation.
  final bool repeat;

  /// Screen reader label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    if (MediaQuery.disableAnimationsOf(context)) {
      return PicoThemedSvg(
        'assets/lottie/static/$name.svg',
        width: width,
        height: height,
        semanticLabel: label,
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color pick(Color l, Color d) => dark ? d : l;
    final colors = <String, Color>{
      'pico-primary': pick(
        PicoBrandPalette.primaryLight,
        PicoBrandPalette.primaryDark,
      ),
      'pico-sky': pick(PicoBrandPalette.skyLight, PicoBrandPalette.skyDark),
      'pico-indigo': pick(
        PicoBrandPalette.indigoLight,
        PicoBrandPalette.indigoDark,
      ),
      'pico-crimson': pick(
        PicoBrandPalette.crimsonLight,
        PicoBrandPalette.crimsonDark,
      ),
      'pico-tint': pick(PicoBrandPalette.tintLight, PicoBrandPalette.tintDark),
    };
    final lottie = LottieBuilder.asset(
      'assets/lottie/$name.json',
      package: 'pico_ui_kit',
      width: width,
      height: height,
      repeat: repeat,
      delegates: LottieDelegates(
        values: [
          for (final e in colors.entries)
            ValueDelegate.color(['**', e.key, '**'], value: e.value),
        ],
      ),
    );
    return label == null
        ? ExcludeSemantics(child: lottie)
        : Semantics(label: label, image: true, child: lottie);
  }
}
