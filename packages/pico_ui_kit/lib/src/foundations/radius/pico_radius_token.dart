import 'package:flutter/material.dart';

/// Radius token definitions for the design system.
abstract final class PicoRadiusToken() {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double full = 9999.0;

  static const BorderRadius borderNone = BorderRadius.zero;
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXl2 = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );

  static const Radius radiusNone = Radius.zero;
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusXl2 = Radius.circular(xl2);
  static const Radius radiusFull = Radius.circular(full);
}
