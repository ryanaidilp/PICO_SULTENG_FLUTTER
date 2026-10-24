import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'color_item.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'Plus Jakarta Sans';

/// WCAG 2.1 contrast ratio thresholds.
enum WcagLevel() {
  /// Contrast ratio >= 7.0 (large text) or >= 4.5 (normal text).
  aaa,

  /// Contrast ratio >= 4.5 (large text) or >= 3.0 (normal text).
  aa,

  /// Below AA threshold.
  fail,
}

/// Calculates the WCAG 2.1 relative luminance of a color.
double relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.03928
      ? channel / 12.92
      : pow((channel + 0.055) / 1.055, 2.4).toDouble();

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates the WCAG 2.1 contrast ratio between two colors.
/// Returns a value between 1.0 (no contrast) and 21.0 (maximum contrast).
double contrastRatio(Color foreground, Color background) {
  final lumFg = relativeLuminance(foreground);
  final lumBg = relativeLuminance(background);
  final lighter = max(lumFg, lumBg);
  final darker = min(lumFg, lumBg);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Determines the WCAG level for a given contrast ratio.
WcagLevel wcagLevel(double ratio) {
  if (ratio >= 7.0) return WcagLevel.aaa;
  if (ratio >= 4.5) return WcagLevel.aa;
  return WcagLevel.fail;
}

/// A contrast pair entry showing foreground on background.
class const ContrastPair({
  required final String label,
  required final Color foreground,
  required final Color background,
});

/// A widget that displays a contrast pair with its WCAG ratio and pass/fail.
class const ContrastPairWidget({required final ContrastPair pair, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(pair.foreground, pair.background);
    final level = wcagLevel(ratio);
    final fgToken = autoResolveTokenName(pair.foreground);
    final bgToken = autoResolveTokenName(pair.background);

    final badgeColor = switch (level) {
      WcagLevel.aaa => const Color(0xFF16A34A),
      WcagLevel.aa => const Color(0xFFF59E0B),
      WcagLevel.fail => const Color(0xFFDC2626),
    };
    final badgeText = switch (level) {
      WcagLevel.aaa => 'AAA',
      WcagLevel.aa => 'AA',
      WcagLevel.fail => 'FAIL',
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pair.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: _testFontFamily,
                    color: pair.foreground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$badgeText ${ratio.toStringAsFixed(1)}:1',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: _testFontFamily,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sample text on background',
            style: TextStyle(
              fontSize: 14,
              fontFamily: _testFontFamily,
              color: pair.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'FG: $fgToken  BG: $bgToken',
            style: TextStyle(
              fontSize: 8,
              fontFamily: _testFontFamily,
              color: pair.foreground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', pair.label));
    properties.add(ColorProperty('foreground', pair.foreground));
    properties.add(ColorProperty('background', pair.background));
  }
}
