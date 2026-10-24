import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_detail_page.dart';
import 'package:infografis/src/presentation/ui/pages/infografis_page.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'harness.dart';

void main() {
  testWidgets(
    'every image failing: grid shows titles, counts and opens detail',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final opened = <String>[];
      await tester.pumpWidget(
        host(InfografisPage(onOpen: opened.add), PagedContent(pages: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PicoImageMissing), findsNWidgets(2));
      expect(find.text('Infografis 100'), findsWidgets);
      expect(find.text('3 gambar'), findsNWidgets(2));
      await tester.tap(find.text('3 gambar').first);
      expect(opened.single, '/info/infografis/100');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail with every image failing: title, source and share work', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final launched = <Uri>[];
    final shared = <String>[];
    await tester.pumpWidget(
      host(
        InfografisDetailPage(
          id: 100,
          syncUrl: false,
          launcher: (u) async {
            launched.add(u);
            return true;
          },
          share: (text, subject) async => shared.add(text),
        ),
        PagedContent(pages: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Infografis 100'), findsWidgets);
    expect(find.text('1 dari 3'), findsOneWidget);
    await tester.tap(find.text('Lihat sumber'));
    expect(launched.single.toString(), 'https://www.instagram.com/p/100/');
    await tester.tap(find.text('Bagikan'));
    expect(shared.single, 'Infografis 100\nhttps://www.instagram.com/p/100/');
  });

  testWidgets(
    'alt text: "<judul>, gambar n dari m", and the page label moves',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const InfografisDetailPage(id: 100, page: 2, syncUrl: false),
          PagedContent(pages: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 dari 3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Infografis 100, gambar 2 dari 3'),
        findsOneWidget,
      );
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3 dari 3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Infografis 100, gambar 3 dari 3'),
        findsOneWidget,
      );
      h.dispose();
    },
  );

  testWidgets(
    'double tap zooms in and out, and a page change resets the zoom',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester);
      await tester.pumpWidget(
        host(
          const InfografisDetailPage(id: 100, syncUrl: false),
          PagedContent(pages: 1),
        ),
      );
      await tester.pumpAndSettle();
      double scale() => tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      final target = find.byType(InteractiveViewer).first;
      Future<void> doubleTap() async {
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      expect(scale(), 1);
      await doubleTap();
      expect(scale(), closeTo(2.5, 0.01));
      await doubleTap();
      expect(scale(), 1);
      await doubleTap();
      expect(scale(), closeTo(2.5, 0.01));
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      final scales = [
        for (final v in tester.widgetList<InteractiveViewer>(
          find.byType(InteractiveViewer),
        ))
          v.transformationController?.value.getMaxScaleOnAxis() ?? 1,
      ];
      expect(scales.every((s) => s == 1), isTrue, reason: '$scales');
    },
  );

  testWidgets('paging: loads page 2 and 3 at the end, then stops', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 700);
    final repo = PagedContent();
    await tester.pumpWidget(host(InfografisPage(onOpen: (_) {}), repo));
    await tester.pumpAndSettle();
    // Short pages do not fill the screen: the list asks for the next at once.
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
    }
    expect(repo.requested, [1, 2, 3], reason: 'page 3 is last: no page 4');
    expect(find.text('Infografis 95'), findsWidgets);
  });

  testWidgets('deep link to an item on page 2 keeps loading until found', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    final repo = PagedContent();
    await tester.pumpWidget(
      host(const InfografisDetailPage(id: 97, syncUrl: false), repo),
    );
    await tester.pumpAndSettle();
    expect(find.text('Infografis 97'), findsWidgets);
    expect(repo.requested, [1, 2]);
  });

  testWidgets('unknown id on the last page is not found; offline state', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester);
    await tester.pumpWidget(
      host(
        const InfografisDetailPage(id: 1, syncUrl: false),
        PagedContent(pages: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Infografis tidak ditemukan.'), findsOneWidget);

    final off = FakeContentRepository()..infographics = fakeFailure();
    await tester.pumpWidget(host(InfografisPage(onOpen: (_) {}), off));
    await tester.pumpAndSettle();
    expect(find.byType(PicoStateView), findsOneWidget);
  });

  testWidgets('english, and text scale 2.0 without overflow', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester, 4000);
    await tester.pumpWidget(
      host(
        InfografisPage(onOpen: (_) {}),
        PagedContent(pages: 1),
        scale: 2,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 images'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(
        const InfografisDetailPage(id: 100, syncUrl: false),
        PagedContent(pages: 1),
        scale: 2,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await setup(tester, AppLocale.id);
  });
}
