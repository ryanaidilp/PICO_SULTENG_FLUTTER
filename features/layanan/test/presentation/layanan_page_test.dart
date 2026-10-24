import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_detail_page.dart';
import 'package:layanan/src/presentation/ui/pages/hospital_list_page.dart';
import 'package:layanan/src/presentation/ui/pages/layanan_page.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'harness.dart';

void main() {
  // A load started in a fake-async zone never completes in the next test.
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  testWidgets('hub: 4 entries open their paths and the archive note shows', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final opened = <String>[];
    await tester.pumpWidget(host(LayananPage(onOpen: opened.add), directory()));
    await tester.pumpAndSettle();
    expect(
      find.text('Data layanan adalah arsip. Hubungi fasilitas sebelum datang.'),
      findsOneWidget,
    );
    for (final t in ['Vaksin', 'Rumah sakit', 'Satgas', 'Isoman']) {
      await tester.tap(find.text(t));
    }
    expect(opened, [
      '/layanan/vaksin',
      '/layanan/rumah-sakit',
      '/layanan/satgas',
      '/layanan/isoman',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list: grouped by kabupaten with beds free of all', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final opened = <String>[];
    await tester.pumpWidget(
      host(HospitalListPage(onOpen: opened.add), directory()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kota Palu'), findsWidgets);
    expect(find.text('Tolitoli'), findsWidgets);
    expect(find.text('21 dari 28 tempat tidur'), findsOneWidget);
    // No bed rows: a sentence, never "0 dari 0".
    // Rows with no beds or a zero total never read "0 dari 0".
    expect(find.text('Belum ada data tempat tidur'), findsNWidgets(2));
    expect(find.textContaining('0 dari 0'), findsNothing);
    await tester.tap(find.text('RS Tk.III 14.06.01 Dr. Sindhu Trisno'));
    expect(opened.single, '/layanan/rumah-sakit/7271025');
  });

  testWidgets('search: "sindhu" finds Dr. Sindhu Trisno, accents fold', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(host(const HospitalListPage(), directory()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sindhu');
    await tester.pumpAndSettle();
    expect(find.text('RS Tk.III 14.06.01 Dr. Sindhu Trisno'), findsOneWidget);
    expect(find.text('RSUD Mokopido Tolitoli'), findsNothing);
    await tester.enterText(find.byType(TextField), 'PETRA');
    await tester.pumpAndSettle();
    expect(find.text('RSUD Luwuk Pétra'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada rumah sakit'), findsOneWidget);
  });

  testWidgets('list: empty, offline and error states', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(const HospitalListPage(), directory(hospitals: const [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada data rumah sakit.'), findsOneWidget);

    final off = directory()..hospitals = fakeFailure();
    await tester.pumpWidget(host(const HospitalListPage(), off));
    await tester.pumpAndSettle();
    expect(find.byType(PicoStateView), findsOneWidget);
  });

  testWidgets('detail 7271025: 3 beds, 3 phone contacts that open tel:, map', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final launched = <Uri>[];
    // The button asks the haptics plugin first; answer "cannot vibrate".
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('haptic_feedback'),
      (_) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('haptic_feedback'),
        null,
      ),
    );
    await tester.pumpWidget(
      host(
        HospitalDetailPage(
          code: '7271025',
          launcher: (u) async {
            launched.add(u);
            return true;
          },
        ),
        directory(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Data terakhir'), findsOneWidget);
    expect(find.byType(PicoWovenBar), findsNWidgets(3));
    expect(find.text('16 dari 22'), findsOneWidget);
    expect(find.text('Jumlah IGD: 2'), findsOneWidget);
    expect(find.text('Buka di peta'), findsWidgets);
    expect(find.text('081213756763'), findsOneWidget);
    await tester.tap(find.text('085256394088'));
    await tester.pump();
    expect(launched.single.scheme, 'tel');
    await tester.tap(find.byType(PicoButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(
      launched.last.toString(),
      anyOf(startsWith('geo:'), startsWith('https://maps.apple.com')),
    );
  });

  testWidgets('detail without coordinates hides the map link', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(const HospitalDetailPage(code: '7205001'), directory()),
    );
    await tester.pumpAndSettle();
    expect(find.text('RSUD Mokopido Tolitoli'), findsWidgets);
    expect(find.text('Buka di peta'), findsNothing);
    expect(find.text('Belum ada kontak.'), findsOneWidget);
    expect(find.text('Belum ada data tempat tidur'), findsOneWidget);
  });

  testWidgets('detail: unknown code shows the not-found state', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(const HospitalDetailPage(code: '0000000'), directory()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rumah sakit tidak ditemukan.'), findsOneWidget);
  });

  testWidgets('english strings', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester);
    await tester.pumpWidget(host(LayananPage(onOpen: (_) {}), directory()));
    await tester.pumpAndSettle();
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Hospitals'), findsOneWidget);
    await setup(tester, AppLocale.id);
  });

  testWidgets('Dynamic Type 2.0: list and detail have no overflow', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    await tester.pumpWidget(
      host(const HospitalListPage(), directory(), scale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(const HospitalDetailPage(code: '7271025'), directory(), scale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
