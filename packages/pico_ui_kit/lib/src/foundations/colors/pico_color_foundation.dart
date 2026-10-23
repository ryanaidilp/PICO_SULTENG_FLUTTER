import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Semantic color foundation for the design system, mapped onto the PICO
/// "Tenun Donggala" brand palette (ADR-0106, DESIGN.md).
///
/// Contrast pairs were computed against the brand paper, surface, cotton and
/// tint grounds: every text pair is at least 4.5:1 in both themes.
/// Status colors reuse brand hues; state is never colour alone (DESIGN.md).
abstract final class PicoColorFoundation() {
  // Backgrounds: paper is the page, surface the card, cotton and tint the layers.
  static const Color bgMain = PicoBrandPalette.paperLight;
  static const Color bgSubtle = PicoBrandPalette.cottonDeepLight;
  static const Color bgStrong = PicoBrandPalette.tintLight;
  static const Color bgInverse = PicoBrandPalette.indigoLight;

  static const Color bgMainDark = PicoBrandPalette.paperDark;
  static const Color bgSubtleDark = PicoBrandPalette.cottonDeepDark;
  static const Color bgStrongDark = PicoBrandPalette.tintDark;
  static const Color bgInverseDark = PicoBrandPalette.indigoDark;

  static const Color bgCard = PicoBrandPalette.surfaceLight;
  static const Color bgCardSecondary = PicoBrandPalette.tintLight;
  static const Color bgCardDark = PicoBrandPalette.surfaceDark;
  static const Color bgCardSecondaryDark = PicoBrandPalette.tintDark;

  // Foreground.
  static const Color foregroundMain = PicoBrandPalette.inkLight;
  static const Color foregroundSubtle = PicoBrandPalette.inkMutedLight;
  static const Color foregroundMuted = PicoBrandPalette.inkMutedLight;
  static const Color foregroundDisabled = PicoBrandPalette.lineStrongLight;
  static const Color foregroundInverse = PicoBrandPalette.onIndigoLight;

  static const Color foregroundMainDark = PicoBrandPalette.inkDark;
  static const Color foregroundSubtleDark = PicoBrandPalette.inkMutedDark;
  static const Color foregroundMutedDark = PicoBrandPalette.inkMutedDark;
  static const Color foregroundDisabledDark = PicoBrandPalette.lineStrongDark;
  static const Color foregroundInverseDark = PicoBrandPalette.onIndigoDark;

  static const Color foregroundSuccess = PicoBrandPalette.recoveredLight;
  static const Color foregroundWarning = PicoBrandPalette.dyeBarkLight;
  static const Color foregroundError = PicoBrandPalette.crimsonLight;
  static const Color foregroundInfo = PicoBrandPalette.primaryStrongLight;
  static const Color foregroundPrimary = PicoBrandPalette.primaryStrongLight;

  static const Color foregroundSuccessDark = PicoBrandPalette.recoveredDark;
  static const Color foregroundWarningDark = PicoBrandPalette.dyeGoldDark;
  static const Color foregroundErrorDark = PicoBrandPalette.crimsonDark;
  static const Color foregroundInfoDark = PicoBrandPalette.primaryDark;

  // Actions. Filled actions use the inverse foreground as text.
  static const Color actionPrimary = PicoBrandPalette.primaryStrongLight;
  static const Color actionPrimaryHover = PicoBrandPalette.indigoLight;
  static const Color actionPrimaryDisabled = PicoBrandPalette.lineLight;
  static const Color actionPrimaryDark = PicoBrandPalette.primaryDark;
  static const Color actionPrimaryHoverDark = PicoBrandPalette.indigoDark;
  static const Color actionPrimaryDisabledDark = PicoBrandPalette.lineDark;

  static const Color actionSecondary = PicoBrandPalette.indigoLight;
  static const Color actionSecondaryHover = PicoBrandPalette.primaryStrongLight;
  static const Color actionSecondaryDisabled = PicoBrandPalette.lineLight;
  static const Color actionSecondaryDark = PicoBrandPalette.indigoDark;
  static const Color actionSecondaryHoverDark = PicoBrandPalette.primaryDark;
  static const Color actionSecondaryDisabledDark = PicoBrandPalette.lineDark;

  static const Color actionDestructive = PicoBrandPalette.crimsonLight;
  static const Color actionDestructiveHover = PicoBrandPalette.dyeMaroonLight;
  static const Color actionDestructiveDisabled = PicoBrandPalette.lineLight;
  static const Color actionDestructiveDark = PicoBrandPalette.crimsonDark;
  static const Color actionDestructiveHoverDark = PicoBrandPalette.crimsonDark;
  static const Color actionDestructiveDisabledDark = PicoBrandPalette.lineDark;

  static const Color actionSuccess = PicoBrandPalette.recoveredLight;
  static const Color actionSuccessHover = PicoBrandPalette.indigoLight;
  static const Color actionSuccessDisabled = PicoBrandPalette.lineLight;
  static const Color actionSuccessDark = PicoBrandPalette.recoveredDark;
  static const Color actionSuccessHoverDark = PicoBrandPalette.primaryDark;
  static const Color actionSuccessDisabledDark = PicoBrandPalette.lineDark;

  // Outlines. outlineMain is the >= 3:1 boundary of active components
  // (WCAG 1.4.11): lineStrong measures 3.3:1 on paper, 5.5:1 on dark paper.
  static const Color outlineMain = PicoBrandPalette.lineStrongLight;
  static const Color outlineStrong = PicoBrandPalette.inkMutedLight;
  static const Color outlineSubtle = PicoBrandPalette.lineLight;
  static const Color outlineFocus = PicoBrandPalette.primaryStrongLight;

  static const Color outlineMainDark = PicoBrandPalette.lineStrongDark;
  static const Color outlineStrongDark = PicoBrandPalette.inkMutedDark;
  static const Color outlineSubtleDark = PicoBrandPalette.lineDark;
  static const Color outlineFocusDark = PicoBrandPalette.primaryDark;

  // Overlays.
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x4D000000);
  static const Color overlayDark = Color(0xB3000000);

  // Status surfaces.
  static const Color successBg = PicoBrandPalette.tintLight;
  static const Color successBgDark = PicoBrandPalette.tintDark;
  static const Color successFg = PicoBrandPalette.recoveredLight;

  static const Color warningBg = PicoBrandPalette.cottonDeepLight;
  static const Color warningBgDark = PicoBrandPalette.cottonDeepDark;
  static const Color warningFg = PicoBrandPalette.dyeBarkLight;

  static const Color errorBg = PicoBrandPalette.cottonDeepLight;
  static const Color errorBgDark = PicoBrandPalette.cottonDeepDark;
  static const Color errorFg = PicoBrandPalette.crimsonLight;

  static const Color infoBg = PicoBrandPalette.tintLight;
  static const Color infoBgDark = PicoBrandPalette.tintDark;
  static const Color infoFg = PicoBrandPalette.primaryStrongLight;
}
