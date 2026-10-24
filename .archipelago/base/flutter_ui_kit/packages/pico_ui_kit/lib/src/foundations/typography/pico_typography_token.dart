import 'package:flutter/material.dart';

/// Typography token definitions for the design system.
abstract final class PicoTypographyToken() {
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const double sizeDisplay1 = 56.0;
  static const double sizeDisplay2 = 48.0;
  static const double sizeDisplay3 = 40.0;

  static const double sizeH1 = 32.0;
  static const double sizeH2 = 28.0;
  static const double sizeH3 = 24.0;
  static const double sizeH4 = 20.0;
  static const double sizeH5 = 18.0;
  static const double sizeH6 = 16.0;

  static const double sizeBodyLarge = 18.0;
  static const double sizeBody = 16.0;
  static const double sizeBodySmall = 14.0;

  static const double sizeCaption = 12.0;
  static const double sizeOverline = 10.0;

  static const double heightDisplay = 1.1;
  static const double heightHeading = 1.25;
  static const double heightBody = 1.5;
  static const double heightCaption = 1.4;

  static const double trackingTight = -0.5;
  static const double trackingNormal = 0.0;
  static const double trackingWide = 0.5;
  static const double trackingWider = 1.0;
}
