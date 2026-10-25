import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

void main() {
  testWidgets('the visible label names the edit box', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: PicoTheme.light(),
        home: const Scaffold(
          body: PicoTextField(label: 'Cari rumah sakit', hint: 'Nama'),
        ),
      ),
    );
    final field = tester.getSemantics(find.byType(EditableText));
    expect(field.label, contains('Cari rumah sakit'));
    expect(field.flagsCollection.isTextField, isTrue);
    // Read once, on the field, not again as a loose text.
    expect(find.bySemanticsLabel(RegExp('Cari rumah sakit')), findsOneWidget);
    h.dispose();
  });
}
