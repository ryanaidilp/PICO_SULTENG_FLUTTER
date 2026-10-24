import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/ui/pages/informasi_page.dart';
import 'package:informasi/src/presentation/ui/pages/tip_page.dart';

import 'harness.dart';

void main() {
  testWidgets('hub: four entries and the six tips open their paths', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final opened = <String>[];
    await tester.pumpWidget(host(InformasiPage(onOpen: opened.add)));
    await settle(tester);
    for (final t in [
      'Infografis',
      'Tentang dan metodologi',
      'Pengaturan',
      'Cuci tangan',
      'Isolasi mandiri',
    ]) {
      await tester.tap(find.text(t));
    }
    expect(opened, [
      '/info/infografis',
      '/info/tentang',
      '/pengaturan',
      '/info/tips/cuci-tangan',
      '/info/tips/isolasi-mandiri',
    ]);
    expect(
      find.text('Gejala dan kapan ke fasilitas kesehatan'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tip: review note, body, external and in-app links', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final external = <Uri>[];
    final inApp = <String>[];
    await tester.pumpWidget(
      host(
        TipPage(
          slug: 'isolasi-mandiri',
          launcher: (u) async {
            external.add(u);
            return true;
          },
          onOpenPath: inApp.add,
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Belum ditinjau tenaga kesehatan'), findsOneWidget);
    expect(find.textContaining('Siapkan termometer'), findsOneWidget);
    // The in-app link goes through the router, not the browser.
    // Tap the link span the way a finger would: through its recognizer.
    TapGestureRecognizer? rec;
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((s) {
        if (s is TextSpan &&
            s.text == 'Gejala dan kapan ke fasilitas kesehatan' &&
            s.recognizer is TapGestureRecognizer) {
          rec = s.recognizer! as TapGestureRecognizer;
        }
        return true;
      });
    }
    expect(rec, isNotNull);
    rec!.onTap!();
    expect(inApp, ['/info/tips/gejala']);
    expect(external, isEmpty);
    // A source opens in the external browser.
    await tester.scrollUntilVisible(find.textContaining('who.int').first, 200);
    await tester.tap(find.textContaining('who.int').first);
    expect(external.single.scheme, 'https');
  });

  testWidgets('tip: unknown slug shows not found; english article loads', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(host(const TipPage(slug: 'nope')));
    await settle(tester);
    expect(find.text('Artikel tidak ditemukan.'), findsOneWidget);

    await setup(tester, AppLocale.en);
    await tester.pumpWidget(
      host(const TipPage(slug: 'gejala'), locale: const Locale('en')),
    );
    await settle(tester);
    expect(
      find.text('Symptoms and when to go to a health facility'),
      findsOneWidget,
    );
    expect(
      find.text('Not yet reviewed by a health professional'),
      findsOneWidget,
    );
    await setup(tester, AppLocale.id);
  });

  testWidgets('text scale 2.0: hub and the longest article do not overflow', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 6000);
    await tester.pumpWidget(host(InformasiPage(onOpen: (_) {}), scale: 2));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(const TipPage(slug: 'gejala'), scale: 2));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
