import 'package:dependencies/state.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home/src/l10n/translations.g.dart';
import 'package:home/src/presentation/bloc/home_bloc.dart';
import 'package:home/src/presentation/bloc/home_event.dart';
import 'package:home/src/presentation/ui/pages/home_page.dart';
import 'package:home/src/presentation/ui/widgets/home_widgets.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';

CaseDay day(
  String iso, {
  int pos = 6812127,
  int rec = 6642003,
  int dec = 161879,
  int act = 8245,
  Rt? rt,
}) => CaseDay(
  date: DateTime.parse(iso),
  daily: const CaseCounts(positive: 0, recovered: 0, deceased: 0, active: 0),
  cumulative: CaseCounts(
    positive: pos,
    recovered: rec,
    deceased: dec,
    active: act,
  ),
  rt: rt,
);

final nationalDay = day('2024-01-14');
final sultengDay = day(
  '2024-01-14',
  pos: 64718,
  rec: 63000,
  dec: 1200,
  act: 518,
);

CaseSeries series() => CaseSeries.fromDays(
  area: const AreaRef.national(),
  areaName: 'Indonesia',
  days: [
    day('2023-07-09', rt: const Rt(value: 0.92, lower: 0.8, upper: 1.04)),
    nationalDay,
  ],
);

/// What the repository's small Rt value holds: the newest non-null day.
LatestRt? latestRtOf(CaseSeries s) {
  for (final d in s.days.reversed) {
    if (d.rt != null) return (date: d.date, rt: d.rt!);
  }
  return null;
}

FakeCaseRepository repo({
  bool cache = false,
  bool failNational = false,
  PicoFailureKind kind = PicoFailureKind.network,
  CaseSeries? rtSeries,
  bool stale = true,
  PicoFailureKind? refreshFailure = PicoFailureKind.network,
}) {
  Either<PicoFailure, DataSnapshot<T>> snap<T>(T data) => failNational
      ? fakeFailure<T>(kind)
      : fakeSnapshot(
          data,
          source: cache ? DataSource.cache : DataSource.network,
          isStale: cache && stale,
          refreshFailure: cache ? refreshFailure : null,
          fetchedAt: DateTime(2024, 1, 12),
        );
  return FakeCaseRepository(
    nationalLatest: snap(nationalDay),
    // `failNational` fails the headline source: Sulawesi Tengah.
    provinces: snap([
      AreaSummary(
        area: const AreaRef.province('72'),
        name: 'Sulawesi Tengah',
        latest: sultengDay,
      ),
      AreaSummary(
        area: const AreaRef.province('11'),
        name: 'Aceh',
        latest: day('2024-01-14', pos: 45092),
      ),
    ]),
    regencies: snap([
      AreaSummary(
        area: const AreaRef.regency('7271'),
        name: 'Kota Palu',
        latest: day('2024-01-14', pos: 13824),
      ),
      AreaSummary(
        area: const AreaRef.regency('7201'),
        name: 'Banggai',
        latest: day('2024-01-14', pos: 8335),
      ),
    ]),
    // No series: Beranda must never ask for one (fullSeriesRequests stays 0).
  )..latestRtResult = fakeSnapshot(latestRtOf(rtSeries ?? series()));
}

Widget host(
  CaseRepository cases, {
  ContentRepository? content,
  ValueChanged<Uri>? onOpenLink,
  Locale locale = const Locale('id'),
  ThemeData? theme,
  double scale = 1,
  ValueChanged<String>? onOpen,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? PicoTheme.light(),
  locale: locale,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('id'), Locale('en')],
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: w!,
  ),
  home: TranslationProvider(
    child: Scaffold(
      body: BlocProvider(
        key: UniqueKey(),
        create: (_) => HomeBloc(cases, content)..add(const HomeStarted()),
        child: HomePage(onOpen: onOpen ?? (_) {}, onOpenLink: onOpenLink),
      ),
    ),
  ),
);

Future<void> setup(WidgetTester tester, AppLocale l) async {
  await tester.runAsync(() => LocaleSettings.setLocale(l));
}

void main() {
  testWidgets('national positive tile shows 6.812.127 in id', (tester) async {
    await setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(repo()));
    await tester.pumpAndSettle();
    expect(find.textContaining('6.812.127'), findsOneWidget);
    expect(find.text('64.718'), findsOneWidget);
  });

  testWidgets('and 6,812,127 in en', (tester) async {
    await setup(tester, AppLocale.en);
    tester.view.physicalSize = const Size(412, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(repo(), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.textContaining('6,812,127'), findsOneWidget);
    expect(find.text('Central Sulawesi'), findsOneWidget);
    await setup(tester, AppLocale.id);
  });

  testWidgets('the archive note ends on the date of the latest national row', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    await tester.pumpWidget(host(repo()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'PICO menyimpan data COVID-19 dari 2 Mar 2020 sampai 14 Jan 2024.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'latest Rt is the newest non-null day, never 0; an all-null series says not computed',
    (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repoUsed = repo();
      await tester.pumpWidget(host(repoUsed));
      await tester.pumpAndSettle();
      expect(find.text('Rt terakhir 0,92 (9 Jul 2023)'), findsOneWidget);
      expect(repoUsed.fullSeriesRequests, 0);
      await tester.pumpWidget(
        host(
          repo(
            rtSeries: CaseSeries.fromDays(
              area: const AreaRef.national(),
              areaName: 'Indonesia',
              days: [nationalDay],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rt belum dihitung untuk periode ini.'), findsOneWidget);
      expect(find.textContaining('0,00'), findsNothing);
    },
  );

  testWidgets(
    'offline with a saved copy renders everything and the stamp says saved data',
    (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(repo(cache: true)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nasional (Indonesia)'), findsOneWidget);
      expect(find.textContaining('data tersimpan'), findsOneWidget);
      expect(find.textContaining('Tidak terhubung'), findsOneWidget);
      expect(find.byType(PicoStateView), findsNothing);
    },
  );

  group('the stamp tells the truth in each state', () {
    Future<void> open(WidgetTester tester, FakeCaseRepository r) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(r));
      await tester.pumpAndSettle();
    }

    testWidgets('a saved copy fresh by policy is not offline (phone bug)', (
      tester,
    ) async {
      await open(tester, repo(cache: true, stale: false, refreshFailure: null));
      expect(find.textContaining('diperbarui'), findsOneWidget);
      expect(find.textContaining('Tidak terhubung'), findsNothing);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('stale with no failure yet: saved, no alarm', (tester) async {
      await open(tester, repo(cache: true, refreshFailure: null));
      expect(find.textContaining('data tersimpan'), findsOneWidget);
      expect(find.textContaining('Tidak terhubung'), findsNothing);
      expect(find.textContaining('Gagal memperbarui'), findsNothing);
    });

    testWidgets('stale and the refresh failed on the server', (tester) async {
      await open(
        tester,
        repo(cache: true, refreshFailure: PicoFailureKind.server),
      );
      expect(find.textContaining('Gagal memperbarui'), findsOneWidget);
      expect(find.textContaining('Tidak terhubung'), findsNothing);
    });

    testWidgets('fresh from the network: updated, no icon', (tester) async {
      await open(tester, repo());
      expect(find.textContaining('diperbarui'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });
  });

  testWidgets('offline with no copy is the offline state for the whole page', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    await tester.pumpWidget(host(repo(failNational: true)));
    await tester.pumpAndSettle();
    expect(find.text('Tidak terhubung'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.textContaining('Nasional (Indonesia)'), findsNothing);
  });

  testWidgets('a server failure with no copy is the error state', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    await tester.pumpWidget(
      host(repo(failNational: true, kind: PicoFailureKind.server)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Tidak terhubung'), findsNothing);
  });

  testWidgets(
    'each quick link has a semantic label and opens the right C07 path',
    (tester) async {
      await setup(tester, AppLocale.id);
      final opened = <String>[];
      final h = tester.ensureSemantics();
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(repo(), onOpen: opened.add));
      await tester.pumpAndSettle();
      final expected = {
        'Statistik': PicoRoutes.statistik(),
        'Peta': PicoRoutes.peta(),
        'Vaksin': PicoRoutes.vaksin,
        'Rumah sakit': PicoRoutes.rumahSakit,
        'Satgas': PicoRoutes.satgas,
        'Isoman': PicoRoutes.isoman,
        'Infografis': PicoRoutes.infografis,
        'Tips kesehatan': PicoRoutes.info,
      };
      for (final e in expected.entries) {
        expect(find.bySemanticsLabel(e.key), findsOneWidget, reason: e.key);
        await tester.tap(find.text(e.key));
        expect(opened.last, e.value, reason: e.key);
      }
      await tester.tap(find.text('Lihat Rt'));
      expect(opened.last, '/statistik/rt?area=national');
      await tester.tap(find.text('Lihat kabupaten'));
      expect(opened.last, PicoRoutes.kabupatenList);
      h.dispose();
    },
  );

  testWidgets(
    'every tile carries a mark next to its change, never colour alone',
    (tester) async {
      await setup(tester, AppLocale.id);
      await tester.pumpWidget(host(repo()));
      await tester.pumpAndSettle();
      // Hero plus three tiles of Sulawesi Tengah: each change starts with a
      // glyph (flat here), not only a colour.
      expect(find.textContaining('■ 0'), findsAtLeastNWidgets(4));
    },
  );

  testWidgets('every tappable target is at least 48 dp and labelled', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    final h = tester.ensureSemantics();
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(repo()));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
    h.dispose();
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('golden ${dark ? 'dark' : 'light'} x${scale.toInt()}', (
        tester,
      ) async {
        await setup(tester, AppLocale.id);
        tester.view.physicalSize = Size(412, scale > 1 ? 4200 : 1900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            repo(),
            content: FakeContentRepository()
              ..banners = fakeSnapshot([
                Banner(
                  id: 1,
                  title: 'Panduan Isolasi Mandiri',
                  link: Uri.parse('https://example.org/isoman'),
                  imageUrl: 'https://banuacoders.com/storage/b1.jpg',
                ),
                const Banner(id: 2, title: 'Vaksin untuk semua'),
              ]),
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
            'goldens/home_${dark ? 'dark' : 'light'}_x${scale.toInt()}.png',
          ),
        );
      }, tags: ['golden']);
    }
  }

  group('banners (T13)', () {
    Banner banner(int i, {String? link}) => Banner(
      id: i,
      title: 'Kabar $i',
      link: link == null ? null : Uri.parse(link),
      imageUrl: 'https://banuacoders.com/storage/b$i.jpg',
    );
    FakeContentRepository content(List<Banner> b) =>
        FakeContentRepository()..banners = fakeSnapshot(b);

    testWidgets('3 banners with missing images: designed text cards, label', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          repo(),
          content: content([
            banner(1, link: 'https://a.example/1'),
            banner(2),
            banner(3),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 dari 3'), findsOneWidget);
      expect(find.text('Kabar 1'), findsOneWidget);
      expect(find.byType(PicoImageMissing), findsWidgets);
      expect(find.bySemanticsLabel('Kabar 1, banner 1 dari 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Banner berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('2 dari 3'), findsOneWidget);
      expect(find.text('Kabar 2'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3 dari 3'), findsOneWidget);
      expect(find.text('Kabar 3'), findsOneWidget);
      // No auto-advance: time passing never changes the page.
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('3 dari 3'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(tester.takeException(), isNull);
      h.dispose();
    });

    testWidgets('tap opens the link outside the app; no link is not a button', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = <Uri>[];
      await tester.pumpWidget(
        host(
          repo(),
          content: content([banner(1, link: 'https://a.example/1')]),
          onOpenLink: opened.add,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 dari 1'), findsNothing); // one banner: no label
      await tester.tap(find.text('Kabar 1'));
      expect(opened.single.toString(), 'https://a.example/1');
    });

    testWidgets('zero banners hide the section', (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(repo(), content: content([])));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('text scale 2.0: the carousel does not overflow', (
      tester,
    ) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(repo(), scale: 2, content: content([banner(1), banner(2)])),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('quick links', () {
    testWidgets('every link resolves to a registered brand icon, has a label '
        'and a semantic button that opens its path', (tester) async {
      await setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = tester.ensureSemantics();
      final opened = <String>[];
      await tester.pumpWidget(host(repo(), onOpen: opened.add));
      await tester.pumpAndSettle();
      final links = quickLinks(AppLocale.id.buildSync());
      expect(links, hasLength(8));
      expect({for (final l in links) l.icon}, hasLength(8), reason: 'distinct');
      for (final l in links) {
        expect(PicoIconRegistry.has(l.icon), isTrue, reason: l.icon);
        expect(l.label, isNotEmpty);
        expect(
          PicoRoutes.patterns.contains(l.path.split('?').first),
          isTrue,
          reason: l.path,
        );
        final node = find.bySemanticsLabel(l.label);
        expect(node, findsWidgets, reason: l.label);
      }
      await tester.ensureVisible(find.text('Rumah sakit'));
      await tester.tap(find.text('Rumah sakit'));
      expect(opened.last, PicoRoutes.rumahSakit);
      h.dispose();
    });
  });
}
