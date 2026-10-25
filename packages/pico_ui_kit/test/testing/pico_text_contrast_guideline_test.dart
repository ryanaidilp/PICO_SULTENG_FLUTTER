import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/testing.dart';

/// The guideline at 1x, the density where the stock guideline measured
/// 1.4:1 on 7:1 text on the Linux runner.
void main() {
  Future<Evaluation> check(
    WidgetTester tester,
    Widget child, {
    Color ground = Colors.white,
  }) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: ground,
          body: Center(child: child),
        ),
      ),
    );
    final e = await picoTextContrastGuideline.evaluate(tester);
    h.dispose();
    return e;
  }

  const style = TextStyle(fontFamily: 'SourceSans3', fontSize: 12);

  testWidgets('thin 12 px text at 7:1 passes at 1x', (tester) async {
    final e = await check(
      tester,
      Text(
        'Data per 14 Jan 2024',
        style: style.copyWith(color: const Color(0xFF535352)),
      ),
    );
    expect(e.passed, isTrue, reason: e.reason);
  });

  testWidgets('12 px text at 2.5:1 fails', (tester) async {
    final e = await check(
      tester,
      Text(
        'Data per 14 Jan 2024',
        style: style.copyWith(color: const Color(0xFF9E9E9E)),
      ),
    );
    expect(e.passed, isFalse);
    expect(e.reason, contains('needs 4.5:1'));
  });

  testWidgets('large text needs 3:1 only', (tester) async {
    final e = await check(
      tester,
      Text(
        '63.614',
        style: style.copyWith(fontSize: 24, color: const Color(0xFF8A8A8A)),
      ),
    );
    expect(e.passed, isTrue, reason: e.reason);
  });

  testWidgets('text hidden from semantics is still checked', (tester) async {
    final e = await check(
      tester,
      Semantics(
        label: 'Total',
        child: ExcludeSemantics(
          child: Text(
            'Total',
            style: style.copyWith(color: const Color(0xFFBDBDBD)),
          ),
        ),
      ),
    );
    expect(e.passed, isFalse);
  });

  testWidgets('ancestor opacity is part of the colour', (tester) async {
    final e = await check(
      tester,
      Opacity(
        opacity: 0.3,
        child: Text('Faded', style: style.copyWith(color: Colors.black)),
      ),
    );
    expect(e.passed, isFalse);
  });

  testWidgets('a filter that repaints the text fails the frame check', (
    tester,
  ) async {
    final e = await check(
      tester,
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFE53935), BlendMode.srcIn),
        child: Text('Filtered', style: style.copyWith(color: Colors.black)),
      ),
    );
    expect(e.passed, isFalse);
    expect(e.reason, contains('frame does not show'));
  });

  testWidgets('a gradient ground is measured at its weak end', (tester) async {
    final e = await check(
      tester,
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF09689B), Color(0xFF8FD3F5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'TOTAL KASUS POSITIF',
            style: style.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
    expect(e.passed, isFalse);
  });

  testWidgets('ink on a near-ink ground fails', (tester) async {
    final e = await check(
      tester,
      Text(
        'Data per 14 Jan 2024',
        style: style.copyWith(color: const Color(0xFF777777)),
      ),
      ground: const Color(0xFF7A7A7A),
    );
    expect(e.passed, isFalse);
    expect(e.reason, contains('needs 4.5:1'));
  });

  testWidgets('a gradient fading towards the ink fails', (tester) async {
    final e = await check(
      tester,
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white, Color(0xFF24221F)],
            stops: [0, 0.6, 1],
          ),
        ),
        child: Text(
          'Kasus positif kumulatif Sulawesi Tengah',
          style: style.copyWith(color: const Color(0xFF24221F)),
        ),
      ),
    );
    expect(e.passed, isFalse);
  });

  testWidgets('a filter that fades the text fails the frame check', (
    tester,
  ) async {
    final e = await check(
      tester,
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFDDDDDD), BlendMode.srcIn),
        child: Text(
          'Filtered',
          style: style.copyWith(fontSize: 16, color: Colors.black),
        ),
      ),
    );
    expect(e.passed, isFalse);
    expect(e.reason, contains('frame does not show'));
  });

  testWidgets('icons are graphics, not text', (tester) async {
    final e = await check(
      tester,
      const Icon(Icons.home, color: Color(0xFFE0E0E0)),
    );
    expect(e.passed, isTrue, reason: e.reason);
  });
}
