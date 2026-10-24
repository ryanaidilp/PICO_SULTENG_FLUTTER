import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/src/foundations/colors/nested/pico_foreground_colors.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_color_foundation.dart';

import '../../util/contrast_checker.dart';

void main() {
  group('PicoForegroundColors semantic contrast', () {
    late PicoForegroundColors light;
    late PicoForegroundColors dark;

    setUp(() {
      light = PicoForegroundColors.light();
      dark = PicoForegroundColors.dark();
    });

    test('light semantic foregrounds clear WCAG AA (>=4.5:1) on bgMain, '
        'bgCard, and their own status tint', () {
      for (final (name, fg, tint) in [
        ('success', light.success, PicoColorFoundation.successBg),
        ('warning', light.warning, PicoColorFoundation.warningBg),
        ('error', light.error, PicoColorFoundation.errorBg),
        ('info', light.info, PicoColorFoundation.infoBg),
      ]) {
        for (final (bgName, bg) in [
          ('bgMain', PicoColorFoundation.bgMain),
          ('bgCard', PicoColorFoundation.bgCard),
          ('own tint', tint),
        ]) {
          final ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name foreground on $bgName is $ratio:1, below AA. '
                'A *600 shade reads fine to the eye but fails WCAG as '
                'text — use a darker shade (see foregroundSuccess doc '
                'comment).',
          );
        }
      }
    });

    test('dark semantic foregrounds clear WCAG AA (>=4.5:1) on bgMainDark, '
        'bgCardDark, and their own dark status tint', () {
      for (final (name, fg, tint) in [
        ('success', dark.success, PicoColorFoundation.successBgDark),
        ('warning', dark.warning, PicoColorFoundation.warningBgDark),
        ('error', dark.error, PicoColorFoundation.errorBgDark),
        ('info', dark.info, PicoColorFoundation.infoBgDark),
      ]) {
        for (final (bgName, bg) in [
          ('bgMainDark', PicoColorFoundation.bgMainDark),
          ('bgCardDark', PicoColorFoundation.bgCardDark),
          ('own dark tint', tint),
        ]) {
          final ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'dark $name foreground on $bgName is $ratio:1, '
                'below AA.',
          );
        }
      }
    });

    test('dark semantic foregrounds are not byte-identical to light '
        '(regression guard — the light shade fails against dark '
        'backgrounds)', () {
      expect(dark.success, isNot(equals(light.success)));
      expect(dark.warning, isNot(equals(light.warning)));
      expect(dark.error, isNot(equals(light.error)));
      expect(dark.info, isNot(equals(light.info)));
    });
  });
}
