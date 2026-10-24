import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/spacing/pico_spacing_token.dart';

/// Spacing foundation providing pre-configured EdgeInsets.
abstract final class PicoSpacingFoundation() {
  static const EdgeInsets allNone = EdgeInsets.zero;
  static const EdgeInsets allXxs = EdgeInsets.all(PicoSpacingToken.xxs);
  static const EdgeInsets allXs = EdgeInsets.all(PicoSpacingToken.xs);
  static const EdgeInsets allSm = EdgeInsets.all(PicoSpacingToken.sm);
  static const EdgeInsets allMd = EdgeInsets.all(PicoSpacingToken.md);
  static const EdgeInsets allLg = EdgeInsets.all(PicoSpacingToken.lg);
  static const EdgeInsets allXl = EdgeInsets.all(PicoSpacingToken.xl);
  static const EdgeInsets allXl2 = EdgeInsets.all(PicoSpacingToken.xl2);
  static const EdgeInsets allXl3 = EdgeInsets.all(PicoSpacingToken.xl3);
  static const EdgeInsets allXl4 = EdgeInsets.all(PicoSpacingToken.xl4);

  static const EdgeInsets horizontalXxs = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xxs,
  );
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xs,
  );
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.sm,
  );
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.md,
  );
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.lg,
  );
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xl,
  );
  static const EdgeInsets horizontalXl2 = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xl2,
  );
  static const EdgeInsets horizontalXl3 = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xl3,
  );
  static const EdgeInsets horizontalXl4 = EdgeInsets.symmetric(
    horizontal: PicoSpacingToken.xl4,
  );

  static const EdgeInsets verticalXxs = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xxs,
  );
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xs,
  );
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.sm,
  );
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.md,
  );
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.lg,
  );
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xl,
  );
  static const EdgeInsets verticalXl2 = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xl2,
  );
  static const EdgeInsets verticalXl3 = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xl3,
  );
  static const EdgeInsets verticalXl4 = EdgeInsets.symmetric(
    vertical: PicoSpacingToken.xl4,
  );
}
