import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'SourceSans3';

/// All known palettes for auto-resolution.
/// When a color is passed without explicit baseColor, we scan all of these.
const Map<String, MaterialColor> knownPalettes = {
  'primary': PicoColorToken.primary,
  'slate': PicoColorToken.slate,
  'secondary': PicoColorToken.secondary,
  'tertiary': PicoColorToken.tertiary,
  'success': PicoColorToken.success,
  'warning': PicoColorToken.warning,
  'error': PicoColorToken.error,
  'info': PicoColorToken.info,
};

/// A widget that displays a single color swatch with label and auto-resolved
/// token name.
///
/// Auto-resolution scans all known palettes from [PicoColorToken] to find
/// which palette and shade the color belongs to (e.g. "primary/600").
/// Falls back to hex code if no match is found.
class const ColorItem({
  required final Color color,
  required final String label,
  final double size = 48.0,
  super.key,
}) extends StatelessWidget {
  String get _colorCode => autoResolveTokenName(color);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size + 24,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: _testFontFamily,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _colorCode,
          style: const TextStyle(fontSize: 9, fontFamily: _testFontFamily),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(StringProperty('label', label));
    properties.add(DoubleProperty('size', size));
  }
}

/// Extension to convert Color to hex string.
extension ColorHex on Color {
  String toHex() {
    final r = (this.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (this.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (this.b * 255).round().toRadixString(16).padLeft(2, '0');
    final a = (this.a * 255).round().toRadixString(16).padLeft(2, '0');
    if (a == 'ff') {
      return '#$r$g$b';
    }
    return '#$a$r$g$b';
  }
}

/// Extension on MaterialColor to resolve shade name from a color value.
extension MaterialColorX on MaterialColor {
  String getNameAndIndex(Color color, String colorName) {
    final argb = color.toARGB32();
    final rgb = argb & 0xFFFFFF;
    final a = (color.a * 255).round();

    for (final entry in {
      50: this[50],
      100: this[100],
      200: this[200],
      300: this[300],
      400: this[400],
      500: this[500],
      600: this[600],
      700: this[700],
      800: this[800],
      900: this[900],
    }.entries) {
      if (entry.value != null && (entry.value!.toARGB32() & 0xFFFFFF) == rgb) {
        if (a == 255) {
          return '$colorName/${entry.key}';
        } else {
          return '$colorName/${entry.key}\n(${(a / 255 * 100).round()}% opacity)';
        }
      }
    }

    return color.toHex().toUpperCase();
  }
}

/// Automatically resolves a color to its token name by scanning all known
/// palettes. Returns e.g. "primary/600" or falls back to hex if no match.
String autoResolveTokenName(Color color) {
  for (final entry in knownPalettes.entries) {
    final result = entry.value.getNameAndIndex(color, entry.key);
    if (!result.startsWith('#')) return result;
  }
  return color.toHex().toUpperCase();
}
