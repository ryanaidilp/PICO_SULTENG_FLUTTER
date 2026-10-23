import 'package:flutter/material.dart';

/// Shadow token definitions for the design system.
abstract final class PicoShadowToken() {
  // Blue-tinted shadows for depth that matches the slate palette
  static const Color shadowColor = Color(0x141E293B);
  static const Color shadowColorDark = Color(0x40000000);

  static const double blurXs = 2.0;
  static const double blurSm = 4.0;
  static const double blurMd = 8.0;
  static const double blurLg = 16.0;
  static const double blurXl = 24.0;
  static const double blur2xl = 32.0;

  static const double spreadNone = 0.0;
  static const double spreadSm = 1.0;
  static const double spreadMd = 2.0;
  static const double spreadLg = 4.0;

  static const Offset offsetXs = Offset(0, 1);
  static const Offset offsetSm = Offset(0, 2);
  static const Offset offsetMd = Offset(0, 4);
  static const Offset offsetLg = Offset(0, 8);
  static const Offset offsetXl = Offset(0, 12);
  static const Offset offset2xl = Offset(0, 16);
}
