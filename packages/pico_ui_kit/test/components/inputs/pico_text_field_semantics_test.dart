import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

void main() {
  testWidgets('the visible label names the edit box, once', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: PicoTheme.light(),
        home: const Scaffold(
          body: PicoTextField(label: 'Cari rumah sakit', hint: 'Nama'),
        ),
      ),
    );
    // Every node of the semantics tree whose label or hint carries the text.
    final hits = <SemanticsData>[];
    void walk(SemanticsNode n) {
      final d = n.getSemanticsData();
      if ('${d.label} ${d.hint}'.contains('Cari rumah sakit')) hits.add(d);
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(
      tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode ??
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
    );
    expect(hits, hasLength(1), reason: 'announced once');
    expect(hits.single.flagsCollection.isTextField, isTrue);
    // Label first, then the hint the field shows: "Cari rumah sakit\nNama".
    expect(hits.single.label, startsWith('Cari rumah sakit'));
    expect(
      RegExp('Cari rumah sakit').allMatches(hits.single.label),
      hasLength(1),
    );
    h.dispose();
  });
}
