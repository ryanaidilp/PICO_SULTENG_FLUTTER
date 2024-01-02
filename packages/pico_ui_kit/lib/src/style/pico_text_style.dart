import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PicoTextStyle {
  const PicoTextStyle._();

  static TextStyle _base({
    int fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration? decoration,
    double? letterSpacing,
  }) =>
      GoogleFonts.sourceSans3(
        fontSize: fontSize * 1.sp,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
        letterSpacing: letterSpacing,
      );

  static TextStyle heading3xl({
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 48,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        letterSpacing: -1.60.w,
      );

  static TextStyle heading2xl({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 40,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        letterSpacing: -0.80.w,
      );

  static TextStyle headingXl({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 32,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        letterSpacing: -0.80.w,
      );

  static TextStyle headingLg({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 24,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        letterSpacing: -0.40.w,
      );

  static TextStyle heading({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 20,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );

  static TextStyle headingSm({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 18,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );

  static TextStyle headingXs({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 16,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );
  static TextStyle labelLg({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 16,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );

  static TextStyle label({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );
  static TextStyle labelSm({
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 12,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );

  static TextStyle bodyLg({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 16,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );

  static TextStyle body({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration? decoration,
  }) =>
      _base(
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );
  static TextStyle bodySm({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 12,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );
  static TextStyle bodyXs({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration? decoration,
  }) =>
      _base(
        fontSize: 10,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
      );
}
