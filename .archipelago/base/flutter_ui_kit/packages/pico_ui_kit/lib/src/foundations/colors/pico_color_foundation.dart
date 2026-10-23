import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_token.dart';

/// Semantic color foundation for the design system.
///
/// Provides color constants organized by purpose for light and dark themes.
abstract final class PicoColorFoundation() {
  // ============================================================
  // Background Colors
  // ============================================================

  // Light theme backgrounds (primary-tinted)
  static const Color bgMain = PicoColorToken.primary50;
  static const Color bgSubtle = PicoColorToken.primary100;
  static const Color bgStrong = PicoColorToken.primary200;
  static const Color bgInverse = PicoColorToken.slate900;

  // Dark theme backgrounds (deep slate, not pure black)
  static const Color bgMainDark = PicoColorToken.slate900;
  static const Color bgSubtleDark = PicoColorToken.slate800;
  static const Color bgStrongDark = PicoColorToken.slate950;
  static const Color bgInverseDark = PicoColorToken.slate50;

  // Card backgrounds
  static const Color bgCard = PicoColorToken.white;
  static const Color bgCardSecondary = PicoColorToken.primary50;
  static const Color bgCardDark = PicoColorToken.slate800;
  static const Color bgCardSecondaryDark = PicoColorToken.slate700;

  // ============================================================
  // Foreground Colors
  // ============================================================

  // Light theme foreground (slate)
  static const Color foregroundMain = PicoColorToken.slate800;
  static const Color foregroundSubtle = PicoColorToken.slate600;
  static const Color foregroundMuted = PicoColorToken.slate400;
  static const Color foregroundDisabled = PicoColorToken.slate300;
  static const Color foregroundInverse = PicoColorToken.white;

  // Dark theme foreground
  static const Color foregroundMainDark = PicoColorToken.slate50;
  static const Color foregroundSubtleDark = PicoColorToken.slate300;
  static const Color foregroundMutedDark = PicoColorToken.slate500;
  static const Color foregroundDisabledDark = PicoColorToken.slate600;
  static const Color foregroundInverseDark = PicoColorToken.slate900;

  // Semantic foreground colors
  //
  // Deliberately the 800 shade, not 600: the 600 shade fails WCAG AA
  // (4.5:1) as text against bgMain, its own *Bg 50-tint, and (for
  // success/warning/info) even plain white — verified by direct
  // contrast-ratio computation, not assumption. 800 clears every one of
  // those backgrounds with margin (6.3-8.3:1). Root-caused from a Kirana
  // color-audit finding.
  static const Color foregroundSuccess = PicoColorToken.success800;
  static const Color foregroundWarning = PicoColorToken.warning800;
  static const Color foregroundError = PicoColorToken.error800;
  static const Color foregroundInfo = PicoColorToken.info800;
  static const Color foregroundPrimary = PicoColorToken.primary600;

  // Dark-theme semantic foreground colors. 800 (the light-theme shade
  // above) fails AA against dark backgrounds — a dark-on-dark color has
  // low contrast for the same reason a light-on-light one does. 300 clears
  // bgMainDark/bgCardDark/successBgDark-and-siblings for all four colors
  // (verified by computation; 400 was close but error400 still failed
  // against errorBgDark specifically, so 300 is used for all four to keep
  // one shade instead of a per-color exception).
  static const Color foregroundSuccessDark = PicoColorToken.success300;
  static const Color foregroundWarningDark = PicoColorToken.warning300;
  static const Color foregroundErrorDark = PicoColorToken.error300;
  static const Color foregroundInfoDark = PicoColorToken.info300;

  // ============================================================
  // Action Colors
  // ============================================================

  // Primary action
  static const Color actionPrimary = PicoColorToken.primary600;
  static const Color actionPrimaryHover = PicoColorToken.primary700;
  static const Color actionPrimaryDisabled = PicoColorToken.primary300;

  // Secondary action (cyan)
  static const Color actionSecondary = PicoColorToken.secondary600;
  static const Color actionSecondaryHover = PicoColorToken.secondary700;
  static const Color actionSecondaryDisabled = PicoColorToken.secondary300;

  // Destructive action
  static const Color actionDestructive = PicoColorToken.error600;
  static const Color actionDestructiveHover = PicoColorToken.error700;
  static const Color actionDestructiveDisabled = PicoColorToken.error300;

  // Success action
  static const Color actionSuccess = PicoColorToken.success600;
  static const Color actionSuccessHover = PicoColorToken.success700;
  static const Color actionSuccessDisabled = PicoColorToken.success300;

  // ============================================================
  // Outline/Border Colors
  // ============================================================
  //
  // WCAG 2.1 SC 1.4.11 (Non-text Contrast) requires >=3:1 for borders that
  // are the only way to identify an *active* UI component's boundary or
  // state — verified by direct computation the same way the foreground
  // colors above were (see that section's doc comment; Archipelago-nink).
  // [outlineMain] backs the text field's normal-state border, the card's
  // outlined variant, the checkbox's enabled border and the icon button's
  // enabled border — all non-exempt, active-state component boundaries.
  // The original slate400/slate700 shades read fine to the eye but
  // measured 2.29:1 (light, vs bgMain) and 1.41-1.72:1 (dark, vs
  // bgCardDark/bgMainDark) — well under the 3:1 floor.
  //
  // [outlineSubtle]/[outlineSubtleDark] are deliberately NOT touched here:
  // every current usage (the text field/checkbox/icon button's *disabled*
  // -state border, the avatar's placeholder fill) is an inactive/disabled
  // component, which SC 1.4.11 explicitly exempts ("Inactive Components").
  // Darkening `outlineSubtle` to pass 3:1 would work against its actual
  // job of visually de-emphasizing disabled controls.
  //
  // [outlineFocus]/[outlineFocusDark] already clear 3:1 (3.99/5.98 against
  // bgMain/bgMainDark) and are unchanged.

  // Light theme borders
  static const Color outlineMain = PicoColorToken.slate500;
  static const Color outlineStrong = PicoColorToken.slate500;
  static const Color outlineSubtle = PicoColorToken.slate200;
  static const Color outlineFocus = PicoColorToken.primary500;

  // Dark theme borders
  //
  // outlineMainDark/outlineStrongDark could not simply mirror light theme's
  // slate500 collapse: slate500 clears bgMainDark at only 3.75:1 and
  // bgCardDark at 3.07:1, a razor-thin margin over the 3:1 floor that
  // anti-aliasing/rounding could erode. Moved further up the (inverted,
  // for dark) scale for headroom: outlineMainDark to slate400 (6.96:1 /
  // 5.71:1) and outlineStrongDark to slate300 (12.02:1 / 9.85:1), which
  // also preserves a visible main < strong hierarchy in dark theme even
  // though light theme's palette has no shade between 400 and 500 to do
  // the same.
  static const Color outlineMainDark = PicoColorToken.slate400;
  static const Color outlineStrongDark = PicoColorToken.slate300;
  static const Color outlineSubtleDark = PicoColorToken.slate800;
  static const Color outlineFocusDark = PicoColorToken.primary400;

  // ============================================================
  // Overlay Colors
  // ============================================================

  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x4D000000);
  static const Color overlayDark = Color(0xB3000000);

  // ============================================================
  // Semantic Status Colors
  // ============================================================

  static const Color successBg = PicoColorToken.success50;
  static const Color successBgDark = PicoColorToken.success900;
  static const Color successFg = PicoColorToken.success800;

  static const Color warningBg = PicoColorToken.warning50;
  static const Color warningBgDark = PicoColorToken.warning900;
  static const Color warningFg = PicoColorToken.warning800;

  static const Color errorBg = PicoColorToken.error50;
  static const Color errorBgDark = PicoColorToken.error900;
  static const Color errorFg = PicoColorToken.error800;

  static const Color infoBg = PicoColorToken.info50;
  static const Color infoBgDark = PicoColorToken.info900;
  static const Color infoFg = PicoColorToken.info800;
}
