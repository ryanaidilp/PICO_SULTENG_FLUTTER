import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font family configuration for the design system.
@immutable
class const PicoFontFamily({
  final String? _bodyFontFamily,
  final String? _headingFontFamily,
  final String? _monoFontFamily,
}) {
  bool get isUsingCustomFonts => _bodyFontFamily != null;

  String get bodyFontFamily =>
      _bodyFontFamily ?? GoogleFonts.plusJakartaSans().fontFamily!;

  String get headingFontFamily =>
      _headingFontFamily ?? GoogleFonts.plusJakartaSans().fontFamily!;

  String get monoFontFamily =>
      _monoFontFamily ?? GoogleFonts.jetBrainsMono().fontFamily!;

  TextTheme applyToTextTheme(TextTheme base) {
    if (_bodyFontFamily != null) {
      return base.apply(fontFamily: _bodyFontFamily);
    }
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }

  TextStyle bodyTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    if (_bodyFontFamily != null) {
      return TextStyle(
        fontFamily: _bodyFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  TextStyle headingTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    if (_headingFontFamily != null) {
      return TextStyle(
        fontFamily: _headingFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  TextStyle monoTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    if (_monoFontFamily != null) {
      return TextStyle(
        fontFamily: _monoFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
