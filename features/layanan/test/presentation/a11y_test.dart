import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_detail_page.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_list_page.dart';
import 'package:layanan/src/presentation/ui/pages/isoman_page.dart';
import 'package:layanan/src/presentation/ui/pages/layanan_page.dart';
import 'package:layanan/src/presentation/ui/pages/satgas_page.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../support.dart';
import 'harness.dart';

/// T29: the four guideline checks for every Layanan page, in id light x1 and
/// en dark x2.
Future<void> guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  expect(tester.takeException(), isNull);
}

void main() {
  final pages = <String, Widget>{
    'layanan hub': LayananPage(onOpen: (_) {}),
    'hospital list': HospitalListPage(onOpen: (_) {}),
    'hospital detail': const HospitalDetailPage(code: '7205001'),
    'satgas': const SatgasPage(),
    'isoman': const IsomanPage(),
  };

  for (final entry in pages.entries) {
    for (final (l, locale, dark, scale) in [
      (AppLocale.id, const Locale('id'), false, 1.0),
      (AppLocale.en, const Locale('en'), true, 2.0),
    ]) {
      final n =
          '${entry.key}, ${l.languageCode} ${dark ? 'dark' : 'light'} '
          'x${scale.toInt()}';
      testWidgets('guidelines: $n', (tester) async {
        await setup(tester, l);
        big(tester, scale == 2 ? 12000 : 6000);
        final h = tester.ensureSemantics();
        await tester.pumpWidget(
          hostAll(
            entry.value,
            dir: directory()..taskForces = fakeSnapshot(taskForces),
            content: FakeContentRepository()
              ..donations = fakeSnapshot([donation])
              ..telemedicines = fakeSnapshot(doctors),
            theme: dark ? PicoTheme.dark() : PicoTheme.light(),
            scale: scale,
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        await guidelines(tester);
        h.dispose();
        await setup(tester, AppLocale.id);
      });
    }
  }
}
