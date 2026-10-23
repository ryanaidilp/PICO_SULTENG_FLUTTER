import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_action_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

import '../../util/contrast_checker.dart';

void main() {
  group('PicoActionColors', () {
    late PicoActionColors light;
    late PicoActionColors dark;

    setUp(() {
      light = PicoActionColors.light();
      dark = PicoActionColors.dark();
    });

    test('dark is not byte-identical to light (regression guard)', () {
      // This is the exact bug from Archipelago-0ixy/Archipelago-66z6: both
      // factories constructed identical values, so dark-mode action-state
      // contrast (buttons, icon buttons, checkboxes, OTP focus states) was
      // never actually tuned. Guard every leaf value so a future revert
      // can't silently re-introduce a byte-for-byte copy.
      final lightValues = [
        light.primary.active,
        light.primary.hover,
        light.primary.disabled,
        light.secondary.active,
        light.secondary.hover,
        light.secondary.disabled,
        light.destructive.active,
        light.destructive.hover,
        light.destructive.disabled,
        light.success.active,
        light.success.hover,
        light.success.disabled,
      ];
      final darkValues = [
        dark.primary.active,
        dark.primary.hover,
        dark.primary.disabled,
        dark.secondary.active,
        dark.secondary.hover,
        dark.secondary.disabled,
        dark.destructive.active,
        dark.destructive.hover,
        dark.destructive.disabled,
        dark.success.active,
        dark.success.hover,
        dark.success.disabled,
      ];

      expect(
        lightValues,
        isNot(equals(darkValues)),
        reason:
            'PicoActionColors.light() and .dark() must not construct '
            'identical state colors.',
      );

      // At minimum, every family's disabled tier must differ — that's the
      // one state every family changes in this fix.
      expect(light.primary.disabled, isNot(equals(dark.primary.disabled)));
      expect(light.secondary.disabled, isNot(equals(dark.secondary.disabled)));
      expect(
        light.destructive.disabled,
        isNot(equals(dark.destructive.disabled)),
      );
      expect(light.success.disabled, isNot(equals(dark.success.disabled)));
    });

    test(
      'filled action text (inverse foreground) clears AA in both themes',
      () {
        // Filled buttons render PicoColorExtension.foreground.inverse on
        // `.active` and `.hover` (paper on blue/crimson in light, dark paper on
        // the lighter dark-theme actions).
        for (final (text, actions) in [
          (PicoColorFoundation.foregroundInverse, light),
          (PicoColorFoundation.foregroundInverseDark, dark),
        ]) {
          for (final a in [
            actions.primary,
            actions.secondary,
            actions.destructive,
            actions.success,
          ]) {
            expect(contrastRatio(text, a.active), greaterThanOrEqualTo(4.5));
            expect(contrastRatio(text, a.hover), greaterThanOrEqualTo(4.5));
          }
        }
      },
    );

    test('dark disabled tiers are visibly muted against a near-black bg', () {
      const slate900 = PicoColorFoundation.bgMainDark;

      for (final pair in [
        dark.primary,
        dark.secondary,
        dark.destructive,
        dark.success,
      ]) {
        final activeContrast = contrastRatio(pair.active, slate900);
        final disabledContrast = contrastRatio(pair.disabled, slate900);
        expect(
          disabledContrast,
          lessThan(activeContrast),
          reason:
              'disabled (${disabledContrast.toStringAsFixed(2)}) should '
              'blend closer to the dark background than active '
              '(${activeContrast.toStringAsFixed(2)}).',
        );
      }
    });
  });
}
