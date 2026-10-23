import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_outline_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

import '../../util/contrast_checker.dart';

void main() {
  group('PicoOutlineColors non-text contrast (WCAG 2.1 SC 1.4.11)', () {
    late PicoOutlineColors light;
    late PicoOutlineColors dark;

    setUp(() {
      light = PicoOutlineColors.light();
      dark = PicoOutlineColors.dark();
    });

    test(
      'light main/strong/focus outlines clear the >=3:1 non-text floor on '
      'bgMain and bgCard (active-state component boundaries — '
      'AppTextFieldConfig/AppCheckbox/AppIconButtonConfig/AppCardConfig)',
      () {
        for (final (name, outline) in [
          ('main', light.main),
          ('strong', light.strong),
          ('focus', light.focus),
        ]) {
          for (final (bgName, bg) in [
            ('bgMain', PicoColorFoundation.bgMain),
            ('bgCard', PicoColorFoundation.bgCard),
          ]) {
            final ratio = contrastRatio(outline, bg);
            expect(
              ratio,
              greaterThanOrEqualTo(3),
              reason:
                  'outline.$name on $bgName is $ratio:1, below the 3:1 '
                  'SC 1.4.11 non-text floor.',
            );
          }
        }
      },
    );

    test('dark main/strong/focus outlines clear the >=3:1 non-text floor on '
        'bgMainDark and bgCardDark', () {
      for (final (name, outline) in [
        ('main', dark.main),
        ('strong', dark.strong),
        ('focus', dark.focus),
      ]) {
        for (final (bgName, bg) in [
          ('bgMainDark', PicoColorFoundation.bgMainDark),
          ('bgCardDark', PicoColorFoundation.bgCardDark),
        ]) {
          final ratio = contrastRatio(outline, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason:
                'dark outline.$name on $bgName is $ratio:1, below the '
                '3:1 SC 1.4.11 non-text floor.',
          );
        }
      }
    });

    test('subtle outline (disabled-state boundary) is exempt from SC 1.4.11 '
        "('Inactive Components') and is deliberately not asserted here — "
        'see the outlineSubtle doc comment in PicoColorFoundation', () {
      // No assertion: this test exists so a future reader who adds one
      // doesn't have to rediscover why subtle isn't in the loops above.
    });

    test('dark outlines are not byte-identical to light (regression guard — '
        'the light shade fails against dark backgrounds)', () {
      expect(dark.main, isNot(equals(light.main)));
      expect(dark.strong, isNot(equals(light.strong)));
    });
  });
}
