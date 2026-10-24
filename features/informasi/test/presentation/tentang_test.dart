import 'dart:io';

import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/domain/review_markers.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/ui/pages/tentang_page.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

Widget host(
  Widget page, {
  FakeContentRepository? content,
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
}) {
  final c = content ?? FakeContentRepository();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? PicoTheme.light(),
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('id'), Locale('en')],
    builder: (ctx, w) => MediaQuery(
      data: MediaQuery.of(
        ctx,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: w!,
    ),
    home: TranslationProvider(
      child: Scaffold(
        body: BlocProvider(
          key: UniqueKey(),
          create: (_) => PartnersCubit(c.watchPartners),
          child: page,
        ),
      ),
    ),
  );
}

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 3000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

FakeContentRepository partners() =>
    FakeContentRepository()
      ..partners = fakeSnapshot([
        Partner(
          name: 'Dinas Kesehatan',
          link: Uri.parse('https://example.org/dinkes'),
          inFooter: true,
        ),
        const Partner(name: 'Komunitas Relawan', inFooter: false),
      ]);

void main() {
  testWidgets('id: the verified Rt method, data period, sources and terms', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 9000);
    await tester.pumpWidget(host(const TentangPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 Mar 2020 sampai 14 Jan 2024'), findsWidgets);
    expect(find.textContaining('EpiEstim (Cori dkk., 2013)'), findsOneWidget);
    expect(
      find.textContaining('rata-rata 7,5 hari, simpangan baku 3,4 hari'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Jendela: 7 hari. Setiap nilai diberi tanggal akhir jendelanya.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('kurang dari 12'), findsOneWidget);
    expect(find.textContaining('rentang kredibel 95%'), findsOneWidget);
    expect(
      find.textContaining('nasional 9 Jul 2023, Sulawesi Tengah 24 Jun 2023'),
      findsOneWidget,
    );
    expect(find.textContaining('m.andrafarm.com (Andra Farm)'), findsOneWidget);
    expect(find.textContaining('bukan hasil pemeriksaan PICO'), findsOneWidget);
    expect(
      find.textContaining(
        'cantumkan PICO Sulteng, m.andrafarm.com, dan sumber aslinya',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('PICO tidak memberi lisensi atas data ini'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ODP dan PDP berhenti setelah 8 Mei 2022'),
      findsOneWidget,
    );
    expect(find.textContaining('berhenti pada 28 Sep 2020'), findsOneWidget);
    expect(find.textContaining('berhenti pada 25 Mar 2022'), findsOneWidget);
    expect(find.textContaining('belum ditinjau tenaga medis'), findsOneWidget);
    expect(
      find.textContaining('Motif tenun Kaili adalah warisan bersama'),
      findsOneWidget,
    );
    expect(
      find.textContaining('tidak ada foto kain asli yang dipakai'),
      findsOneWidget,
    );
    expect(find.textContaining('Taiganja dan Sambulugana'), findsOneWidget);
    expect(
      find.textContaining('belum ditinjau oleh Dinas Kebudayaan'),
      findsOneWidget,
    );
    expect(find.textContaining('tidak menjamin ketepatannya'), findsOneWidget);
  });

  testWidgets('the Rt numbers on the page come from RtMethod', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester, 9000);
    await tester.pumpWidget(
      host(const TentangPage(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'mean ${RtMethod.serialIntervalMean} days, standard deviation '
        '${RtMethod.serialIntervalSd} days',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Window: ${RtMethod.windowDays} days'),
      findsOneWidget,
    );
    expect(
      find.textContaining('fewer than ${RtMethod.minCasesInWindow} new cases'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '${RtMethod.credibleIntervalPercent}% credible interval',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Last values: national 9 Jul 2023'.replaceAll(
          '9 Jul 2023',
          'Jul 9, 2023',
        ),
      ),
      findsOneWidget,
    );
    await setup(tester, AppLocale.id);
  });

  testWidgets('#metodologi scrolls the Metodologi section into view', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 700);
    await tester.pumpWidget(host(const TentangPage(anchor: 'metodologi')));
    await tester.pumpAndSettle();
    final y = tester.getTopLeft(find.text('Metodologi').first).dy;
    expect(y, lessThan(300), reason: 'the heading is at the top of the view');
    expect(
      tester.getTopLeft(find.text('Tentang PICO')).dy,
      isNegative,
      reason: 'the first section scrolled out above the view',
    );
  });

  testWidgets(
    'partners are text, links open outside the app, offline copy ok',
    (tester) async {
      await setup(tester, AppLocale.id);
      big(tester, 9000);
      final launched = <Uri>[];
      await tester.pumpWidget(
        host(
          TentangPage(
            launcher: (u) async {
              launched.add(u);
              return true;
            },
          ),
          content: partners(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Komunitas Relawan'), findsOneWidget);
      await tester.ensureVisible(find.text('Dinas Kesehatan'));
      await tester.tap(find.text('Dinas Kesehatan'));
      expect(launched.single.toString(), 'https://example.org/dinkes');
      expect(find.byType(PicoImage), findsNothing, reason: 'logos are dead');
    },
  );

  testWidgets('the open licence page button calls the licence page', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    big(tester, 9000);
    var shown = 0;
    await tester.pumpWidget(host(TentangPage(onShowLicenses: () => shown++)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lisensi perangkat lunak terbuka'));
    await tester.tap(find.text('Lisensi perangkat lunak terbuka'));
    expect(shown, 1);
  });

  group('open review markers', () {
    testWidgets('the two owner-open items show as "Dalam peninjauan"', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      big(tester, 9000);
      await tester.pumpWidget(host(const TentangPage()));
      await tester.pumpAndSettle();
      expect(find.text('Dalam peninjauan'), findsNWidgets(2));
      for (final id in kOpenReviewMarkers) {
        expect(find.byKey(ValueKey('review-$id')), findsOneWidget, reason: id);
      }
      // The code licence is decided: MIT, for the code only.
      expect(
        find.textContaining('berlisensi MIT, hak cipta 2026 Banua Coder'),
        findsOneWidget,
      );
      expect(find.textContaining('hanya mencakup kode'), findsOneWidget);
      expect(find.textContaining('tidak otomatis termasuk'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('review-metodologi-kode')),
        findsNothing,
      );
    });

    test('the markers are exactly the two open owner items (O-7, O-12)', () {
      expect(kOpenReviewMarkers, ['metodologi-peta', 'metodologi-budaya']);
    });

    test('a release build fails while a marker is open', () {
      expect(() => assertNoOpenReviewMarkers(release: true), throwsStateError);
      // No marker, or not a release build: fine.
      assertNoOpenReviewMarkers(release: true, open: const []);
      assertNoOpenReviewMarkers(release: false);
    });

    test('release content must be final (run with PICO_RELEASE_CONTENT=true '
        'to gate a release)', () {
      // Fails the release pipeline while any marker is open.
      expect(
        kReleaseContent && kOpenReviewMarkers.isNotEmpty,
        isFalse,
        reason: 'Resolve ${kOpenReviewMarkers.join(', ')} before release',
      );
    });
  });

  test('the repository carries an MIT LICENSE for Banua Coder', () {
    final f = File('../../LICENSE');
    expect(f.existsSync(), isTrue);
    final t = f.readAsStringSync();
    expect(t, startsWith('MIT License'));
    expect(t, contains('Copyright (c) 2026 Banua Coder'));
  });

  testWidgets('scale 2.0 and english have no overflow', (tester) async {
    await setup(tester, AppLocale.en);
    big(tester, 16000);
    await tester.pumpWidget(
      host(const TentangPage(), scale: 2, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('About PICO'), findsOneWidget);
    expect(find.text('Under review'), findsNWidgets(2));
    expect(
      find.textContaining('MIT licence, copyright 2026 Banua Coder'),
      findsOneWidget,
    );
    expect(find.textContaining('covers the code only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await setup(tester, AppLocale.id);
  });

  testWidgets('golden tentang light x1 and dark x2', (tester) async {
    for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
      await setup(tester, AppLocale.id);
      big(tester, scale == 2 ? 16000 : 6500);
      await tester.pumpWidget(
        host(
          const TentangPage(),
          content: partners(),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/tentang_${dark ? 'dark' : 'light'}_x${scale.toInt()}.png',
        ),
      );
    }
  }, tags: ['golden']);
}
