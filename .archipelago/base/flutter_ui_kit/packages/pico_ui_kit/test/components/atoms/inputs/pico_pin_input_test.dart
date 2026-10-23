import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Widget-behavior tests for [PicoPinInput]'s error-visual reset.
///
/// Covers Archipelago-59kx: `_hasError` (a raw `errorText != null` check)
/// used to gate dot coloring directly, so every dot stayed red for as long
/// as the caller's `errorText` prop remained non-null. In real integrations
/// (e.g. an app-lock PIN screen backed by domain state) `errorText` only
/// clears once the *next* full submission resolves, not on every keystroke
/// — so every dot stayed solid red throughout the user's entire next
/// attempt instead of resetting per-keystroke like standard iOS/Android PIN
/// UX. These tests assert the fixed behavior directly, since animated
/// per-frame dot colors aren't meaningfully verifiable from a golden image.
///
/// `revealDuration: null` disables the brief last-digit-reveal feature
/// everywhere here — it's an unrelated feature that would otherwise swap
/// the just-typed dot for a text glyph (a different keyed widget) for a
/// few hundred ms, which is orthogonal to what these tests assert.
void main() {
  Color? dotColor(WidgetTester tester, int index) {
    final container = tester.widget<AnimatedContainer>(
      find.byKey(ValueKey('dot-$index')),
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  Widget wrap(Widget child) => MaterialApp(
    theme: PicoTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  group('PicoPinInput error-visual reset (Archipelago-59kx)', () {
    testWidgets('dots render in the active color with no error', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          PicoPinInput(
            controller: controller,
            useNativeKeyboard: false,
            revealDuration: null,
          ),
        ),
      );

      final activeColor = dotColor(tester, 0);
      expect(activeColor, isNotNull);
    });

    testWidgets('a fresh error transition turns filled dots red', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          PicoPinInput(
            controller: controller,
            useNativeKeyboard: false,
            enableHapticFeedback: false,
            enableShakeOnError: false,
            revealDuration: null,
          ),
        ),
      );
      final activeColor = dotColor(tester, 0);

      // Rebuild with a fresh errorText — the shake-triggering transition
      // (`_hasError && _previousErrorText != widget.errorText`).
      await tester.pumpWidget(
        wrap(
          PicoPinInput(
            controller: controller,
            useNativeKeyboard: false,
            enableHapticFeedback: false,
            enableShakeOnError: false,
            revealDuration: null,
            errorText: 'Wrong PIN',
          ),
        ),
      );
      await tester.pump();

      final errorColor = dotColor(tester, 0);
      expect(errorColor, isNot(equals(activeColor)));
    });

    testWidgets(
      'dots reset to the active color the instant the user retypes, even '
      'though errorText is still non-null (the Archipelago-59kx repro)',
      (tester) async {
        final controller = TextEditingController(text: '123456');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          wrap(
            PicoPinInput(
              controller: controller,
              useNativeKeyboard: false,
              enableHapticFeedback: false,
              enableShakeOnError: false,
              revealDuration: null,
            ),
          ),
        );
        final activeColor = dotColor(tester, 0);

        // Wrong PIN submitted — parent surfaces a domain-driven error.
        await tester.pumpWidget(
          wrap(
            PicoPinInput(
              controller: controller,
              useNativeKeyboard: false,
              enableHapticFeedback: false,
              enableShakeOnError: false,
              revealDuration: null,
              errorText: 'Wrong PIN',
            ),
          ),
        );
        await tester.pump();
        final errorColor = dotColor(tester, 0);
        expect(errorColor, isNot(equals(activeColor)));

        // Real Kirana/Lumbung usage pattern: the parent clears the pin
        // controller after a failed attempt (dots go back to empty) but
        // does NOT clear `errorText` — that only clears once the *next*
        // full submission resolves, not on every keystroke.
        controller.clear();
        await tester.pump();

        // Type the first digit of a brand-new attempt. `errorText` is
        // still "Wrong PIN" the entire time — this is the actual bug
        // scenario, not the trivial case where the parent clears it.
        controller.text = '1';
        await tester.pump();

        final resetColor = dotColor(tester, 0);
        expect(resetColor, equals(activeColor));
        expect(resetColor, isNot(equals(errorColor)));

        // Keep typing — every filled dot stays in the active color, not
        // error color, for the rest of this attempt.
        controller.text = '12';
        await tester.pump();
        expect(dotColor(tester, 0), equals(activeColor));
        expect(dotColor(tester, 1), equals(activeColor));
      },
    );

    testWidgets('a fresh error on the retried attempt turns dots red again', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);
      var errorText = 'Wrong PIN';

      Widget buildWithError() => wrap(
        PicoPinInput(
          controller: controller,
          useNativeKeyboard: false,
          enableHapticFeedback: false,
          enableShakeOnError: false,
          revealDuration: null,
          errorText: errorText,
        ),
      );

      await tester.pumpWidget(buildWithError());
      await tester.pump();
      final firstErrorColor = dotColor(tester, 0);

      // User retypes a full new attempt without the error ever clearing.
      controller.clear();
      await tester.pump();
      controller.text = '654321';
      await tester.pump();
      expect(dotColor(tester, 0), isNot(equals(firstErrorColor)));

      // That new attempt also fails — a genuinely new error string arrives
      // (still non-null throughout, but a different value).
      errorText = 'Wrong PIN again';
      await tester.pumpWidget(buildWithError());
      await tester.pump();

      expect(dotColor(tester, 0), equals(firstErrorColor));
    });

    testWidgets('still shakes on a fresh error transition (unchanged '
        'behavior)', (tester) async {
      final controller = TextEditingController(text: '123456');
      addTearDown(controller.dispose);

      Transform findShakeTransform() => tester.widget<Transform>(
        find.byWidgetPredicate(
          (widget) => widget is Transform && widget.child is GestureDetector,
        ),
      );

      await tester.pumpWidget(
        wrap(
          PicoPinInput(
            controller: controller,
            useNativeKeyboard: false,
            enableHapticFeedback: false,
            revealDuration: null,
          ),
        ),
      );

      await tester.pumpWidget(
        wrap(
          PicoPinInput(
            controller: controller,
            useNativeKeyboard: false,
            enableHapticFeedback: false,
            revealDuration: null,
            errorText: 'Wrong PIN',
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(findShakeTransform().transform.getTranslation().x, isNot(0));

      await tester.pumpAndSettle();
      expect(findShakeTransform().transform.getTranslation().x, 0);
    });
  });
}
