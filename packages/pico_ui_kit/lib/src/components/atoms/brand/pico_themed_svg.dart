import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Loads brand SVGs that use `var(--pico-x, #hex)` fills and swaps each token
/// for the theme colour before drawing (brand README). Results are cached per
/// asset and brightness.
abstract final class PicoSvgSource {
  static const String package = 'pico_ui_kit';

  static final Map<String, Future<String>> _cache = {};

  /// Forgets cached SVG text. Tests call this because a future started inside
  /// a fake-async zone never completes in the next test.
  @visibleForTesting
  static void clearCache() => _cache.clear();

  static final RegExp _var = RegExp(
    r'var\(--pico-([a-z-]+),\s*(#[0-9A-Fa-f]{3,8})\)',
  );

  static Map<String, Color> _tokens(Brightness b) {
    final dark = b == Brightness.dark;
    return {
      'paper': dark ? PicoBrandPalette.paperDark : PicoBrandPalette.paperLight,
      'surface': dark
          ? PicoBrandPalette.surfaceDark
          : PicoBrandPalette.surfaceLight,
      'cotton-deep': dark
          ? PicoBrandPalette.cottonDeepDark
          : PicoBrandPalette.cottonDeepLight,
      'tint': dark ? PicoBrandPalette.tintDark : PicoBrandPalette.tintLight,
      'indigo': dark
          ? PicoBrandPalette.indigoDark
          : PicoBrandPalette.indigoLight,
      'sky': dark ? PicoBrandPalette.skyDark : PicoBrandPalette.skyLight,
      'primary': dark
          ? PicoBrandPalette.primaryDark
          : PicoBrandPalette.primaryLight,
      'crimson': dark
          ? PicoBrandPalette.crimsonDark
          : PicoBrandPalette.crimsonLight,
      'positive': dark
          ? PicoBrandPalette.positiveDark
          : PicoBrandPalette.positiveLight,
      'recovered': dark
          ? PicoBrandPalette.recoveredDark
          : PicoBrandPalette.recoveredLight,
      'deceased': dark
          ? PicoBrandPalette.deceasedDark
          : PicoBrandPalette.deceasedLight,
      'active': dark
          ? PicoBrandPalette.activeDark
          : PicoBrandPalette.activeLight,
      'rt': dark ? PicoBrandPalette.rtDark : PicoBrandPalette.rtLight,
      'ink': dark ? PicoBrandPalette.inkDark : PicoBrandPalette.inkLight,
      'ink-muted': dark
          ? PicoBrandPalette.inkMutedDark
          : PicoBrandPalette.inkMutedLight,
      'line': dark ? PicoBrandPalette.lineDark : PicoBrandPalette.lineLight,
      'line-strong': dark
          ? PicoBrandPalette.lineStrongDark
          : PicoBrandPalette.lineStrongLight,
    };
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// Substitutes theme colours into [svg]. Unknown tokens keep their fallback.
  static String themed(String svg, Brightness brightness) {
    final tokens = _tokens(brightness);
    return svg.replaceAllMapped(_var, (m) {
      final c = tokens[m.group(1)];
      return c == null ? m.group(2)! : _hex(c);
    });
  }

  static Future<String> _raw(String asset) async {
    try {
      return await rootBundle.loadString('packages/$package/$asset');
    } on FlutterError {
      // The package's own tests see its assets without the prefix.
      return rootBundle.loadString(asset);
    }
  }

  /// The themed SVG text of [asset] (a path under `assets/`).
  static Future<String> load(String asset, Brightness brightness) =>
      _cache.putIfAbsent(
        '$asset|${brightness.name}',
        () async => themed(await _raw(asset), brightness),
      );
}

/// Draws a brand SVG with theme colours. Shows nothing until it loads.
class PicoThemedSvg extends StatelessWidget {
  /// Creates the widget for an asset path such as `assets/lottie/static/pico-loading.svg`.
  const new(
    this.asset, {
    this.width,
    this.height,
    this.semanticLabel,
    this.fit = BoxFit.contain,
    super.key,
  });

  /// Asset path inside `pico_ui_kit`.
  final String asset;

  /// Width, or null for the SVG size.
  final double? width;

  /// Height, or null for the SVG size.
  final double? height;

  /// Screen reader label. Null hides the image from semantics.
  final String? semanticLabel;

  /// Fit.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return FutureBuilder<String>(
      future: PicoSvgSource.load(asset, brightness),
      builder: (context, snap) {
        if (!snap.hasData) return SizedBox(width: width, height: height);
        return SvgPicture.string(
          snap.data!,
          width: width,
          height: height,
          fit: fit,
          semanticsLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        );
      },
    );
  }
}
