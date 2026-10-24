import 'package:flutter/material.dart';

/// Primitive color tokens for the design system.
///
/// These are raw color values that should not be used directly in widgets.
/// Instead, use semantic colors via `PicoColorExtension`.
abstract final class PicoColorToken() {
  // ============================================================
  // Primary palette - Indigo
  // ============================================================
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);
  static const Color primary950 = Color(0xFF1E1B4B);

  /// Primary MaterialColor for Flutter theme integration.
  static const MaterialColor primary = MaterialColor(0xFF6366F1, <int, Color>{
    50: primary50,
    100: primary100,
    200: primary200,
    300: primary300,
    400: primary400,
    500: primary500,
    600: primary600,
    700: primary700,
    800: primary800,
    900: primary900,
  });

  // ============================================================
  // Neutral palette - Slate (blue-tinted, not pure gray)
  // ============================================================
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  /// Slate MaterialColor for Flutter theme integration.
  static const MaterialColor slate = MaterialColor(0xFF64748B, <int, Color>{
    50: slate50,
    100: slate100,
    200: slate200,
    300: slate300,
    400: slate400,
    500: slate500,
    600: slate600,
    700: slate700,
    800: slate800,
    900: slate900,
  });

  // Backward compatibility aliases
  static const Color gray50 = slate50;
  static const Color gray100 = slate100;
  static const Color gray200 = slate200;
  static const Color gray300 = slate300;
  static const Color gray400 = slate400;
  static const Color gray500 = slate500;
  static const Color gray600 = slate600;
  static const Color gray700 = slate700;
  static const Color gray800 = slate800;
  static const Color gray900 = slate900;
  static const Color gray950 = slate950;
  static const MaterialColor gray = slate;

  // ============================================================
  // Secondary palette - Cyan (tropical water between islands)
  // ============================================================
  static const Color secondary50 = Color(0xFFECFEFF);
  static const Color secondary100 = Color(0xFFCFFAFE);
  static const Color secondary200 = Color(0xFFA5F3FC);
  static const Color secondary300 = Color(0xFF67E8F9);
  static const Color secondary400 = Color(0xFF22D3EE);
  static const Color secondary500 = Color(0xFF06B6D4);
  static const Color secondary600 = Color(0xFF0891B2);
  static const Color secondary700 = Color(0xFF0E7490);
  static const Color secondary800 = Color(0xFF155E75);
  static const Color secondary900 = Color(0xFF164E63);
  static const Color secondary950 = Color(0xFF083344);

  /// Secondary MaterialColor for Flutter theme integration.
  static const MaterialColor secondary = MaterialColor(0xFF06B6D4, <int, Color>{
    50: secondary50,
    100: secondary100,
    200: secondary200,
    300: secondary300,
    400: secondary400,
    500: secondary500,
    600: secondary600,
    700: secondary700,
    800: secondary800,
    900: secondary900,
  });

  // ============================================================
  // Tertiary palette - Amber (sunlight, warmth accents)
  // ============================================================
  static const Color tertiary50 = Color(0xFFFFFBEB);
  static const Color tertiary100 = Color(0xFFFEF3C7);
  static const Color tertiary200 = Color(0xFFFDE68A);
  static const Color tertiary300 = Color(0xFFFCD34D);
  static const Color tertiary400 = Color(0xFFFBBF24);
  static const Color tertiary500 = Color(0xFFF59E0B);
  static const Color tertiary600 = Color(0xFFD97706);
  static const Color tertiary700 = Color(0xFFB45309);
  static const Color tertiary800 = Color(0xFF92400E);
  static const Color tertiary900 = Color(0xFF78350F);
  static const Color tertiary950 = Color(0xFF451A03);

  /// Tertiary MaterialColor for Flutter theme integration.
  static const MaterialColor tertiary = MaterialColor(0xFFF59E0B, <int, Color>{
    50: tertiary50,
    100: tertiary100,
    200: tertiary200,
    300: tertiary300,
    400: tertiary400,
    500: tertiary500,
    600: tertiary600,
    700: tertiary700,
    800: tertiary800,
    900: tertiary900,
  });

  // ============================================================
  // Success palette - Green
  // ============================================================
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFFBBF7D0);
  static const Color success300 = Color(0xFF86EFAC);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF166534);
  static const Color success900 = Color(0xFF14532D);
  static const Color success950 = Color(0xFF052E16);

  /// Success MaterialColor for Flutter theme integration.
  static const MaterialColor success = MaterialColor(0xFF16A34A, <int, Color>{
    50: success50,
    100: success100,
    200: success200,
    300: success300,
    400: success400,
    500: success500,
    600: success600,
    700: success700,
    800: success800,
    900: success900,
  });

  // ============================================================
  // Warning palette - Amber
  // ============================================================
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning200 = Color(0xFFFDE68A);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning400 = Color(0xFFFBBF24);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);
  static const Color warning800 = Color(0xFF92400E);
  static const Color warning900 = Color(0xFF78350F);
  static const Color warning950 = Color(0xFF451A03);

  /// Warning MaterialColor for Flutter theme integration.
  static const MaterialColor warning = MaterialColor(0xFFD97706, <int, Color>{
    50: warning50,
    100: warning100,
    200: warning200,
    300: warning300,
    400: warning400,
    500: warning500,
    600: warning600,
    700: warning700,
    800: warning800,
    900: warning900,
  });

  // ============================================================
  // Error palette - Red
  // ============================================================
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error900 = Color(0xFF7F1D1D);
  static const Color error950 = Color(0xFF450A0A);

  /// Error MaterialColor for Flutter theme integration.
  static const MaterialColor error = MaterialColor(0xFFDC2626, <int, Color>{
    50: error50,
    100: error100,
    200: error200,
    300: error300,
    400: error400,
    500: error500,
    600: error600,
    700: error700,
    800: error800,
    900: error900,
  });

  // ============================================================
  // Info palette - Cyan
  // ============================================================
  static const Color info50 = Color(0xFFECFEFF);
  static const Color info100 = Color(0xFFCFFAFE);
  static const Color info200 = Color(0xFFA5F3FC);
  static const Color info300 = Color(0xFF67E8F9);
  static const Color info400 = Color(0xFF22D3EE);
  static const Color info500 = Color(0xFF06B6D4);
  static const Color info600 = Color(0xFF0891B2);
  static const Color info700 = Color(0xFF0E7490);
  static const Color info800 = Color(0xFF155E75);
  static const Color info900 = Color(0xFF164E63);
  static const Color info950 = Color(0xFF083344);

  /// Info MaterialColor for Flutter theme integration.
  static const MaterialColor info = MaterialColor(0xFF0891B2, <int, Color>{
    50: info50,
    100: info100,
    200: info200,
    300: info300,
    400: info400,
    500: info500,
    600: info600,
    700: info700,
    800: info800,
    900: info900,
  });

  // ============================================================
  // Pure colors
  // ============================================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}
