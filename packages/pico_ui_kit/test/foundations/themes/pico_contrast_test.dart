import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../util/contrast_checker.dart';

void main() {
  for (final (name, c) in [
    ('light', PicoColorExtension.light()),
    ('dark', PicoColorExtension.dark()),
  ]) {
    group('contrast ($name)', () {
      test('text on grounds is at least 4.5:1', () {
        final grounds = [
          c.background.main,
          c.background.card,
          c.background.subtle,
        ];
        for (final fg in [
          c.foreground.main,
          c.foreground.subtle,
          c.foreground.muted,
        ]) {
          for (final bg in grounds) {
            expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
          }
        }
        for (final (fg, bg) in [
          (c.foreground.success, c.background.success),
          (c.foreground.warning, c.background.warning),
          (c.foreground.error, c.background.error),
          (c.foreground.info, c.background.info),
          (c.foreground.inverse, c.background.inverse),
          (c.action.primary.active, c.background.main),
        ]) {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        }
      });

      test('filled action text is at least 4.5:1', () {
        for (final a in [
          c.action.primary,
          c.action.secondary,
          c.action.destructive,
          c.action.success,
        ]) {
          expect(
            contrastRatio(c.foreground.inverse, a.active),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(c.foreground.inverse, a.hover),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('active outlines are at least 3:1 (WCAG 1.4.11)', () {
        for (final bg in [c.background.main, c.background.card]) {
          expect(contrastRatio(c.outline.main, bg), greaterThanOrEqualTo(3));
        }
      });
    });
  }

  test('state colors are at least 4.5:1 on paper in both themes', () {
    for (final (s, bg) in [
      (PicoStateColors.light, PicoBrandPalette.paperLight),
      (PicoStateColors.dark, PicoBrandPalette.paperDark),
    ]) {
      for (final state in PicoState.values) {
        expect(contrastRatio(s.of(state), bg), greaterThanOrEqualTo(4.5));
      }
    }
  });
}
