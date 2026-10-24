import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../util/app_component_test_wrapper.dart';

/// Builds the light theme with its radius extension replaced by [radius].
ThemeData _themeWithRadius(PicoRadiusExtension radius) {
  final base = PicoTheme.light(fontFamily: testFontFamily);
  return base.copyWith(
    extensions: [
      radius,
      ...base.extensions.values.where((e) => e is! PicoRadiusExtension),
    ],
  );
}

void main() {
  group('PicoRadiusExtension overrides', () {
    final radius =
        PicoRadiusExtension.standard().copyWith(md: 20) as PicoRadiusExtension;

    test('presets derive from the extension values', () {
      expect(radius.border.md, BorderRadius.circular(20));
      expect(radius.circular.md, const Radius.circular(20));
      expect(radius.border.sm, BorderRadius.circular(PicoRadiusToken.sm));
    });

    testWidgets('copyWith(md: 20) changes the PicoCard corner radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _themeWithRadius(radius),
          home: const PicoCard(child: SizedBox.square(dimension: 40)),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PicoCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('copyWith(md: 20) changes the PicoButton corner radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _themeWithRadius(radius),
          home: Scaffold(
            body: PicoButton(label: 'Go', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final shape = button.style!.shape!.resolve(<WidgetState>{});
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(20),
      );
    });
  });

  group('PicoTypographyExtension.standard(sizes:)', () {
    test('applies the size scale and keeps token sizes for missing keys', () {
      final typography = PicoTypographyExtension.standard(
        fontFamily: testFontFamily,
        sizes: const {'h1': 40, 'body': 15},
      );

      expect(typography.heading.h1.fontSize, 40);
      expect(typography.body.regular.fontSize, 15);
      expect(typography.body.medium.fontSize, 15);
      expect(typography.button.large.fontSize, 15);
      expect(typography.heading.h2.fontSize, PicoTypographyToken.sizeH2);
    });
  });
}
