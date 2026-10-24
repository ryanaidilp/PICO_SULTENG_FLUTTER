import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

void main() {
  testWidgets('PicoDropdown shows the choice, is 48 dp and reports a pick', (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PicoTheme.dark(),
        home: Scaffold(
          body: Center(
            child: PicoDropdown<int>(
              semanticLabel: 'Tahun',
              value: 2023,
              items: const [
                PicoDropdownItem(2023, '2023'),
                PicoDropdownItem(2024, '2024'),
              ],
              onChanged: picked.add,
            ),
          ),
        ),
      ),
    );
    expect(find.text('2023'), findsOneWidget);
    expect(tester.getSize(find.byType(PicoDropdown<int>)).height, 48);
    expect(
      tester.getSemantics(find.byType(PicoDropdown<int>)),
      matchesSemantics(label: 'Tahun', value: '2023'),
    );
    await tester.tap(find.text('2023'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024').last);
    await tester.pumpAndSettle();
    expect(picked, [2024]);
  });
}
