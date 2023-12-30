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
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.sourceSans3(
        fontSize: fontSize * 1.sp,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
        height: height,
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
        height: 0.02.h,
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
        height: 0.03.h,
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
        height: 0.04.h,
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
        height: 0.06.h,
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
        height: 0.07.h,
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
        height: 0.08.h,
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
        height: 0.09.h,
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
        height: 0.09.h,
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
        height: 0.10.h,
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
        height: 0.12.h,
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
        height: 0.09.h,
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
        height: 0.1.h,
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
        height: 0.12.h,
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
        height: 0.16.h,
      );
}
