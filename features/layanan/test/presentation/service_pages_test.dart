import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/isoman_page.dart';
import 'package:layanan/src/presentation/ui/pages/satgas_page.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../support.dart';
import 'harness.dart';

void main() {
  group('Satgas', () {
    FakeDirectoryRepository dir() =>
        directory()..taskForces = fakeSnapshot(taskForces);

    testWidgets('Banggai shows 2 members, each with a phone action', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final h = tester.ensureSemantics();
      final launched = <Uri>[];
      await tester.pumpWidget(
        hostAll(
          SatgasPage(
            launcher: (u) async {
              launched.add(u);
              return true;
            },
          ),
          dir: dir(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Kontak ini dari masa pandemi dan bisa sudah tidak berlaku.'),
        findsOneWidget,
      );
      // Collapsed: the state is announced.
      expect(
        find.bySemanticsLabel('Banggai, 2 kontak, tertutup'),
        findsOneWidget,
      );
      expect(find.textContaining('Anang'), findsNothing);
      await tester.tap(find.text('Banggai').last);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Banggai, 2 kontak, terbuka'),
        findsOneWidget,
      );
      expect(find.text('dr. Anang (Kepala Dinkes Banggai)'), findsOneWidget);
      expect(find.text('Ibu Nur Datu Adam (Jubir)'), findsOneWidget);
      expect(find.text('081241415651'), findsOneWidget);
      expect(find.text('085281691921'), findsOneWidget);
      await tester.tap(find.text('085281691921'));
      expect(launched.single.scheme, 'tel');
      // Collapse again.
      await tester.tap(find.text('Banggai').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Anang'), findsNothing);
      h.dispose();
    });

    testWidgets('chip filters to one kabupaten; search finds a member', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester);
      await tester.pumpWidget(hostAll(const SatgasPage(), dir: dir()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kota Palu'));
      await tester.pumpAndSettle();
      expect(find.text('Pak Budi'), findsOneWidget);
      expect(find.text('Banggai'), findsOneWidget); // only the chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua kabupaten'));
      await tester.enterText(find.byType(TextField), 'ANANG');
      await tester.pumpAndSettle();
      expect(find.text('dr. Anang (Kepala Dinkes Banggai)'), findsOneWidget);
      expect(find.text('Ibu Nur Datu Adam (Jubir)'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('Tidak ada satgas'), findsOneWidget);
    });

    testWidgets('offline with no copy shows the offline state', (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final off = directory()
        ..taskForces = fakeFailure(PicoFailureKind.network);
      await tester.pumpWidget(hostAll(const SatgasPage(), dir: off));
      await tester.pumpAndSettle();
      expect(find.byType(PicoStateView), findsOneWidget);
    });
  });

  group('Isoman', () {
    FakeContentRepository content() => FakeContentRepository()
      ..donations = fakeSnapshot([donation])
      ..telemedicines = fakeSnapshot(doctors);

    testWidgets('the safety note is the first thing read, before the title', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(hostAll(const IsomanPage(), content: content()));
      await tester.pumpAndSettle();
      final note = find.textContaining('PICO tidak memeriksanya');
      expect(note, findsOneWidget);
      final noteY = tester.getTopLeft(note).dy;
      expect(noteY, lessThan(tester.getTopLeft(find.text('Isoman')).dy));
      // And it is the first labelled semantics node of the list.
      String? first(SemanticsNode n) {
        if (n.label.isNotEmpty) return n.label;
        for (final c in n.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )) {
          final l = first(c);
          if (l != null) return l;
        }
        return null;
      }

      expect(
        first(tester.getSemantics(find.byType(ListView).first)),
        contains('PICO tidak memeriksanya'),
      );
      h.dispose();
    });

    testWidgets('copy: digits only on the clipboard, announced', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(hostAll(const IsomanPage(), content: content()));
      await tester.pumpAndSettle();
      expect(find.text('Untuk Kawan Baik'), findsWidgets);
      expect(find.text('Menerima barang'), findsOneWidget);
      expect(find.text('7921 0246 85'), findsOneWidget);
      await tester.tap(find.byTooltip('Salin BCA, a.n. Yaumil'));
      await tester.pump();
      expect(copied, '7921024685');
      expect(find.text('Nomor rekening disalin'), findsOneWidget);
    });

    testWidgets('every image missing: no broken-image widget, designed state', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester);
      await tester.pumpWidget(hostAll(const IsomanPage(), content: content()));
      await tester.pumpAndSettle();
      expect(find.byType(PicoImageMissing), findsWidgets);
      expect(find.byIcon(Icons.broken_image), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
      'telemedicine: Telegram opens https://t.me, free filter, price text',
      (tester) async {
        await setup(tester, AppLocale.id);
        big(tester);
        final launched = <Uri>[];
        await tester.pumpWidget(
          hostAll(
            IsomanPage(
              launcher: (u) async {
                launched.add(u);
                return true;
              },
            ),
            content: content(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Telemedicine'));
        await tester.pumpAndSettle();
        expect(find.text('dr. Evans Suryani'), findsOneWidget);
        expect(find.text('dr. Berbayar'), findsOneWidget);
        expect(find.text('Gratis'), findsWidgets);
        expect(find.text('Berbayar'), findsOneWidget);
        expect(find.text('Senin-Jumat, 07:00-20:00 WIB'), findsOneWidget);
        expect(find.text('Jadwal belum tercatat'), findsOneWidget);
        await tester.tap(find.text('evansevansevans'));
        expect(launched.single.toString(), 'https://t.me/evansevansevans');
        await tester.tap(find.widgetWithText(ChoiceChip, 'Gratis'));
        await tester.pumpAndSettle();
        expect(find.text('dr. Berbayar'), findsNothing);
      },
    );

    testWidgets('english and text scale 2.0 without overflow', (tester) async {
      await setup(tester, AppLocale.en);
      big(tester, 6000);
      await tester.pumpWidget(
        hostAll(
          const IsomanPage(),
          content: content(),
          scale: 2,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('PICO does not check them'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Telemedicine'));
      await tester.pumpAndSettle();
      expect(find.text('Free'), findsWidgets);
      expect(tester.takeException(), isNull);
      await setup(tester, AppLocale.id);
    });
  });
}
