import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';
import 'package:vaksin/src/l10n/translations.g.dart';

import 'harness.dart';

void main() {
  // A load started in a fake-async zone never completes in the next test.
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  testWidgets(
    'health worker dose 1 reads 100,36% with the exceeds-target note; group with no target says so',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      await tester.pumpWidget(host(stats(), directory()));
      await tester.pumpAndSettle();
      expect(find.text('Dosis 1: 100,36%'), findsOneWidget);
      expect(find.text('Dosis 1 melebihi target'), findsOneWidget);
      expect(find.text('Dosis 2 melebihi target'), findsNothing);
      expect(find.text('Tidak ada target'), findsOneWidget);
      expect(find.text('Sasaran: 2.240.548 orang'), findsOneWidget);
      expect(find.text('Dosis 1: 3,65%'), findsOneWidget);
      expect(find.text('Tenaga kesehatan'), findsOneWidget);
    },
  );

  testWidgets('english: 100.36% and "exceeds target"', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester);
    await tester.pumpWidget(
      host(stats(), directory(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dose 1: 100.36%'), findsOneWidget);
    expect(find.text('Dose 1 exceeds target'), findsOneWidget);
    await setup(tester, AppLocale.id);
  });

  testWidgets(
    'scope switch loads the national series; the stamp shows the latest row date',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final s = stats();
      await tester.pumpWidget(host(s, directory()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Data per 4 Mei 2021'), findsOneWidget);
      await tester.tap(find.text('Nasional'));
      await tester.pumpAndSettle();
      expect(s.calls[VaccinationScope.national], 1);
      expect(find.text('Sasaran: 208.265.720 orang'), findsOneWidget);
      expect(find.textContaining('Data per 1 Feb 2021'), findsOneWidget);
    },
  );

  testWidgets(
    'locations: grouped by kabupaten, one semantics node each, null quota and stock hidden',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(host(stats(), directory()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lokasi'));
      await tester.pumpAndSettle();
      expect(find.text('Banggai'), findsOneWidget);
      expect(find.text('Kota Palu'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Gerai Vaksinasi Presisi Mapolda, Jl. Soekarno-Hatta, Palu, Jam: 08:00 - 12:00, Dosis 1',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Kuota'),
        findsOneWidget,
        reason: 'only the location that has a quota',
      );
      expect(find.text('Kuota harian: 120'), findsOneWidget);
      expect(find.text('Stok tersisa: 35'), findsOneWidget);
      expect(find.textContaining('Kuota harian: 0'), findsNothing);
      h.dispose();
    },
  );

  testWidgets(
    'offline with no copy is the offline state; locations load only when opened',
    (tester) async {
      await setup(tester, AppLocale.id);
      final s = CountingStats()..vaccination = {};
      await tester.pumpWidget(host(s, directory()));
      await tester.pumpAndSettle();
      expect(find.text('Tidak terhubung'), findsOneWidget);
    },
  );

  testWidgets('guidelines pass; text scale 2.0 has no overflow', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(stats(), directory(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
    h.dispose();
  });
}
