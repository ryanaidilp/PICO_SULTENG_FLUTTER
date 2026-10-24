import 'package:flutter/material.dart';

/// Font family configuration for the design system.
///
/// Source Sans 3 for text and headings, as in the original app. It is a
/// variable font shipped in this package, so the app never fetches a font at
/// runtime. Every style sets its `wght` axis explicitly (the Source
/// Sans 3 default instance is ExtraLight) and uses tabular figures.
@immutable
class PicoFontFamily {
  /// Creates a font family set. The defaults are the bundled brand fonts.
  const new({
    this.bodyFontFamily = 'SourceSans3',
    this.headingFontFamily = 'SourceSans3',
    this.monoFontFamily = 'SourceSans3',
    this.package = 'pico_ui_kit',
  });

  /// Family for body text.
  final String bodyFontFamily;

  /// Family for display and headings.
  final String headingFontFamily;

  /// Family for code-like text (tabular Source Sans 3).
  final String monoFontFamily;

  /// Package that bundles the fonts. Null when a test registers bare names.
  final String? package;

  /// Always true: fonts are bundled, never fetched.
  bool get isUsingCustomFonts => true;

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Heading weight range.
  static const double _displayMinWeight = 600;
  static const double _displayMaxWeight = 800;

  TextStyle _style(
    String family, {
    required List<FontVariation> variations,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => TextStyle(
    fontFamily: family,
    package: package,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    fontFeatures: _tabular,
    fontVariations: variations,
  );

  double _wght(FontWeight? w) => (w ?? FontWeight.w400).value.toDouble();

  /// Text style for body copy.
  TextStyle bodyTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => _style(
    bodyFontFamily,
    variations: [FontVariation.weight(_wght(fontWeight))],
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Text style for display and headings (Source Sans 3, bold).
  TextStyle headingTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => _style(
    headingFontFamily,
    variations: [
      FontVariation.weight(
        _wght(fontWeight).clamp(_displayMinWeight, _displayMaxWeight),
      ),
    ],
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Text style for code-like text.
  TextStyle monoTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) => _style(
    monoFontFamily,
    variations: [FontVariation.weight(_wght(fontWeight))],
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// The text theme already carries per-style families, so it is returned as is.
  TextTheme applyToTextTheme(TextTheme base) => base;
}
