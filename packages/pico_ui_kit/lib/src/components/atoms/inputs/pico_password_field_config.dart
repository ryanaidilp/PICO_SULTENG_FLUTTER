import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';

/// Password strength level for the strength indicator.
enum PasswordStrength() {
  /// No password entered.
  none,

  /// Weak password (< 6 chars or only one character type).
  weak,

  /// Fair password (6-7 chars with 2 character types).
  fair,

  /// Good password (8+ chars with 3 character types).
  good,

  /// Strong password (12+ chars with all character types).
  strong,
}

/// Extension to get visual properties for password strength.
extension PasswordStrengthX on PasswordStrength {
  /// Get the color for this strength level.
  Color color(PicoColorExtension colors) => switch (this) {
    PasswordStrength.none => colors.foreground.muted,
    PasswordStrength.weak => colors.foreground.error,
    PasswordStrength.fair => Colors.orange,
    PasswordStrength.good => Colors.lightGreen,
    PasswordStrength.strong => colors.foreground.success,
  };

  /// Get the label for this strength level.
  String get label => switch (this) {
    PasswordStrength.none => '',
    PasswordStrength.weak => 'Weak',
    PasswordStrength.fair => 'Fair',
    PasswordStrength.good => 'Good',
    PasswordStrength.strong => 'Strong',
  };

  /// Get the progress value (0.0 - 1.0) for this strength level.
  double get progress => switch (this) {
    PasswordStrength.none => 0.0,
    PasswordStrength.weak => 0.25,
    PasswordStrength.fair => 0.5,
    PasswordStrength.good => 0.75,
    PasswordStrength.strong => 1.0,
  };
}
