import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peta/src/l10n/translations.g.dart';
import 'package:peta/src/presentation/ui/widgets/peta_widgets.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'peta_test.dart' show big, host, repo, setup, settle;

/// T29: guideline checks on the Peta page, both views, both languages, both
/// themes, normal and double text size.
Future<void> guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  expect(tester.takeException(), isNull);
}

void main() {
  for (final (l, locale, dark, scale) in [
    (AppLocale.id, const Locale('id'), false, 1.0),
    (AppLocale.en, const Locale('en'), true, 2.0),
  ]) {
    final n = '${l.languageCode} ${dark ? 'dark' : 'light'} x${scale.toInt()}';

    testWidgets('map view meets the guidelines ($n)', (tester) async {
      await setup(tester, l);
      big(tester, scale == 2 ? 4200 : 3000);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          repo(),
          locale: locale,
          scale: scale,
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
        ),
      );
      await settle(tester);
      await guidelines(tester);
      h.dispose();
    });

    testWidgets('list view meets the guidelines ($n)', (tester) async {
      await setup(tester, l);
      big(tester, scale == 2 ? 5200 : 3000);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          repo(),
          locale: locale,
          scale: scale,
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
        ),
      );
      await settle(tester);
      await tester.tap(find.text(l == AppLocale.id ? 'Daftar' : 'List'));
      await settle(tester);
      await guidelines(tester);
      h.dispose();
    });
  }

  testWidgets('the map is one labelled region and every mark is a button', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(repo()));
    await settle(tester);
    var marks = 0;
    void walk(SemanticsNode n) {
      if (n.label.contains(', positif ') && n.label.endsWith('2024')) {
        marks++;
        final data = n.getSemanticsData();
        expect(
          data.flagsCollection.isButton,
          isTrue,
          reason: 'mark "${n.label}" is not a button',
        );
        expect(n.rect.width, greaterThanOrEqualTo(44), reason: n.label);
      }
      for (final c in n.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        walk(c);
      }
    }

    walk(tester.getSemantics(find.byType(PetaMap)));
    expect(marks, 13);
    h.dispose();
  });
}
