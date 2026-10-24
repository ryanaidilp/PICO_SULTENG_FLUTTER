import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../../helpers/golden_test_helpers.dart';

Widget app(
  ThemeData theme,
  Widget child, {
  Locale locale = const Locale('id'),
  double scale = 1,
  bool noAnim = true,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  locale: locale,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('id'), Locale('en')],
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: noAnim),
    child: w!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

Future<void> prime(WidgetTester tester, Brightness b) =>
    tester.runAsync(() async {
      for (final a in [
        'assets/illustrations/pico-state-empty.svg',
        'assets/illustrations/pico-state-error.svg',
        'assets/illustrations/pico-state-offline.svg',
        'assets/illustrations/pico-state-not-found.svg',
        'assets/lottie/static/pico-loading.svg',
      ]) {
        await PicoSvgSource.load(a, b);
      }
    });

const contacts = [
  Contact(kind: ContactKind.phone, label: 'Telepon', value: '081213756763'),
  Contact(
    kind: ContactKind.whatsapp,
    label: 'WhatsApp',
    value: '6285256087018',
  ),
  Contact(kind: ContactKind.fax, label: 'Faks', value: '0451123'),
];

void main() {
  setUp(PicoSvgSource.clearCache);

  group('PicoImage URL rules (ADR-0113)', () {
    test('empty, null, relative, bare file and dead host are not usable', () {
      for (final u in [
        '',
        '   ',
        null,
        'donations/July2021/x.jpg',
        'detexi.png',
        'https://banuacoders.com/corona/x.png',
        'https://www.banuacoders.com/x.png',
        'ftp://host/x.png',
      ]) {
        expect(PicoImageUrl.isUsable(u), isFalse, reason: '$u');
      }
      expect(PicoImageUrl.isUsable('https://i.ibb.co/mq0ZH12/1.jpg'), isTrue);
      expect(PicoImageUrl.isUsable('http://example.org/a.png'), isTrue);
    });

    testWidgets('unusable URLs show the missing state with no image widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoImage(
            kind: PicoImageKind.infographic,
            url: 'x.png',
            title: 'Judul infografik',
          ),
        ),
      );
      expect(find.text('Judul infografik'), findsOneWidget);
      expect(find.byType(PicoImageMissing), findsOneWidget);
    });

    testWidgets('a missing image keeps its alt text', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoImage(
            kind: PicoImageKind.infographic,
            url: 'https://banuacoders.com/a.png',
            title: 'Judul',
            semanticLabel: 'Judul, gambar 2 dari 3',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Judul, gambar 2 dari 3'), findsOneWidget);
      h.dispose();
    });

    testWidgets('a banner without an image is a text card with the title', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoImage(
            kind: PicoImageKind.banner,
            title: 'Panduan Isolasi Mandiri',
          ),
        ),
      );
      expect(find.text('Panduan Isolasi Mandiri'), findsOneWidget);
    });
  });

  group('PicoDataStamp', () {
    final fetched = DateTime(2024, 1, 15, 9);
    final now = fetched.add(const Duration(hours: 3));

    testWidgets('network copy, Indonesian', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDataStamp(
            dataDate: DateTime(2024, 1, 14),
            fetchedAt: fetched,
            now: now,
          ),
        ),
      );
      expect(
        find.text('Data per 14 Jan 2024 · diperbarui 3 jam lalu'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('network copy, English', (tester) async {
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDataStamp(
            dataDate: DateTime(2024, 1, 14),
            fetchedAt: fetched,
            now: now,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Data as of Jan 14, 2024 · updated 3 hours ago'),
        findsOneWidget,
      );
    });

    testWidgets(
      'cached copy says saved data, offline icon and the word "Tidak terhubung"',
      (tester) async {
        await tester.pumpWidget(
          app(
            PicoTheme.light(),
            PicoDataStamp(
              dataDate: DateTime(2024, 1, 14),
              fetchedAt: fetched,
              offline: true,
              isStale: true,
              now: fetched.add(const Duration(days: 2)),
            ),
          ),
        );
        expect(
          find.text(
            'Data per 14 Jan 2024 · data tersimpan, 2 hari lalu · Tidak terhubung',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      },
    );

    Future<void> stampOf(
      WidgetTester tester, {
      bool stale = false,
      bool offline = false,
      bool failed = false,
      Duration age = const Duration(hours: 3),
    }) => tester.pumpWidget(
      app(
        PicoTheme.light(),
        PicoDataStamp(
          dataDate: DateTime(2024, 1, 14),
          fetchedAt: fetched,
          isStale: stale,
          offline: offline,
          refreshFailed: failed,
          now: fetched.add(age),
        ),
      ),
    );

    testWidgets('a saved copy still fresh by policy is NOT offline', (
      tester,
    ) async {
      // Offline-first: the app did not need the network, so no icon, no
      // "Tidak terhubung".
      await stampOf(tester);
      expect(find.textContaining('Tidak terhubung'), findsNothing);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('stale and the refresh has not failed: saved, no alarm', (
      tester,
    ) async {
      await stampOf(tester, stale: true, age: const Duration(days: 8));
      expect(
        find.text('Data per 14 Jan 2024 · data tersimpan, 8 hari lalu'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('stale and the refresh failed (server): says so, not offline', (
      tester,
    ) async {
      await stampOf(
        tester,
        stale: true,
        failed: true,
        age: const Duration(days: 8),
      );
      expect(
        find.text(
          'Data per 14 Jan 2024 · data tersimpan, 8 hari lalu · Gagal memperbarui',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Tidak terhubung'), findsNothing);
    });

    testWidgets('truly offline: cloud-off icon and "Tidak terhubung"', (
      tester,
    ) async {
      await stampOf(tester, stale: true, offline: true);
      expect(find.textContaining('Tidak terhubung'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('is a live region', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoDataStamp(
            dataDate: DateTime(2024, 1, 14),
            fetchedAt: fetched,
            now: now,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PicoDataStamp)),
        matchesSemantics(
          isLiveRegion: true,
          label: 'Data per 14 Jan 2024 · diperbarui 3 jam lalu',
        ),
      );
      h.dispose();
    });
  });

  group('PicoStateView', () {
    testWidgets('error and offline retry once', (tester) async {
      var n = 0;
      await prime(tester, Brightness.light);
      await tester.pumpWidget(
        app(PicoTheme.light(), PicoStateView.error(onRetry: () => n++)),
      );
      await tester.tap(find.text('Coba lagi'));
      expect(n, 1);
      await tester.pumpWidget(
        app(PicoTheme.light(), PicoStateView.offline(onRetry: () => n++)),
      );
      expect(find.text('Tidak terhubung'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(n, 2);
    });

    testWidgets('loading is the plain progress ring, no Lottie', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(PicoTheme.light(), const PicoStateView.loading(), noAnim: false),
      );
      expect(find.byType(LottieBuilder), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty and not-found use the default copy', (tester) async {
      await tester.pumpWidget(
        app(PicoTheme.light(), const PicoStateView.empty()),
      );
      expect(find.text('Belum ada data'), findsOneWidget);
      await tester.pumpWidget(
        app(PicoTheme.light(), const PicoStateView.notFound()),
      );
      expect(find.text('Halaman atau data tidak ditemukan.'), findsOneWidget);
    });
  });

  group('PicoContactActions', () {
    testWidgets('tap opens the link externally, fax is copy only', (
      tester,
    ) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          PicoContactActions(
            contacts: [
              Contact(
                kind: ContactKind.phone,
                label: 'Telepon',
                value: '0812',
                uri: Uri.parse('tel:0812'),
              ),
              const Contact(
                kind: ContactKind.fax,
                label: 'Faks',
                value: '0451123',
              ),
            ],
            launcher: (u) async {
              opened.add(u);
              return true;
            },
          ),
        ),
      );
      await tester.tap(find.text('0812'));
      expect(opened, [Uri.parse('tel:0812')]);
      await tester.tap(find.text('0451123'));
      expect(opened.length, 1, reason: 'fax has no link');
    });

    testWidgets('copy puts the value on the clipboard and says Disalin', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
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
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoCopyField(label: 'No. rekening', value: '7921024685'),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(copied, '7921024685');
      expect(find.text('Disalin'), findsOneWidget);
    });

    testWidgets('copyValue and copiedMessage override what is copied', (
      tester,
    ) async {
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
      await tester.pumpWidget(
        app(
          PicoTheme.light(),
          const PicoCopyField(
            label: 'No. rekening',
            value: '7921 0246 85',
            copyValue: '7921024685',
            copiedMessage: 'Nomor rekening disalin',
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(copied, '7921024685');
      expect(find.text('Nomor rekening disalin'), findsOneWidget);
    });

    testWidgets('tap target and labelled tap target guidelines pass', (
      tester,
    ) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(
        app(PicoTheme.light(), const PicoContactActions(contacts: contacts)),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    test('icon key per kind is registered', () {
      for (final k in ContactKind.values) {
        expect(PicoIconRegistry.has(contactIconKey(k)), isTrue, reason: k.name);
      }
    });
  });

  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testGoldenSceneWithFonts('states and missing images $name x2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final b = dark ? Brightness.dark : Brightness.light;
      await prime(tester, b);
      await tester.pumpWidget(
        app(
          dark ? PicoTheme.dark() : PicoTheme.light(),
          ListView(
            children: [
              SizedBox(
                height: 480,
                child: PicoStateView.offline(onRetry: () {}),
              ),
              SizedBox(height: 480, child: PicoStateView.error(onRetry: () {})),
              const SizedBox(height: 420, child: PicoStateView.empty()),
              const SizedBox(height: 420, child: PicoStateView.notFound()),
              const PicoImageMissing(
                kind: PicoImageKind.banner,
                title: 'Panduan Isolasi Mandiri',
              ),
              const SizedBox(height: 12),
              const PicoImageMissing(
                kind: PicoImageKind.infographic,
                title: 'Yang Wajib Kamu Tahu Soal Vaksin Booster',
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PicoImageMissing(kind: PicoImageKind.bankLogo),
                  PicoImageMissing(kind: PicoImageKind.partner),
                ],
              ),
              const SizedBox(height: 12),
              PicoDataStamp(
                dataDate: DateTime(2024, 1, 14),
                fetchedAt: DateTime(2024, 1, 12),
                isStale: true,
                now: DateTime(2024, 1, 14),
              ),
              const SizedBox(height: 12),
              const PicoContactActions(contacts: contacts),
              const PicoCopyField(
                label: 'No. rekening BCA',
                value: '7921024685',
              ),
            ],
          ),
          scale: 2,
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/states_media_${name}_x2.png'),
      );
    }, tags: ['golden']);
  }
}
