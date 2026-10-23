import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/shadows/pico_shadow_token.dart';

/// Shadow foundation providing pre-configured box shadows.
abstract final class PicoShadowFoundation() {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blurXs,
      offset: PicoShadowToken.offsetXs,
    ),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blurSm,
      offset: PicoShadowToken.offsetSm,
    ),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blurMd,
      offset: PicoShadowToken.offsetMd,
    ),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blurLg,
      offset: PicoShadowToken.offsetLg,
    ),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blurXl,
      offset: PicoShadowToken.offsetXl,
    ),
  ];
  static const List<BoxShadow> xl2 = [
    BoxShadow(
      color: PicoShadowToken.shadowColor,
      blurRadius: PicoShadowToken.blur2xl,
      offset: PicoShadowToken.offset2xl,
    ),
  ];

  static const List<BoxShadow> xsDark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blurXs,
      offset: PicoShadowToken.offsetXs,
    ),
  ];
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blurSm,
      offset: PicoShadowToken.offsetSm,
    ),
  ];
  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blurMd,
      offset: PicoShadowToken.offsetMd,
    ),
  ];
  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blurLg,
      offset: PicoShadowToken.offsetLg,
    ),
  ];
  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blurXl,
      offset: PicoShadowToken.offsetXl,
    ),
  ];
  static const List<BoxShadow> xl2Dark = [
    BoxShadow(
      color: PicoShadowToken.shadowColorDark,
      blurRadius: PicoShadowToken.blur2xl,
      offset: PicoShadowToken.offset2xl,
    ),
  ];
}
