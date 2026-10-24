import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locale_core/locale_core.dart' show PicoLocale;
import 'package:pengaturan/src/l10n/translations.g.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_bloc.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_event.dart';
import 'package:pengaturan/src/presentation/ui/pages/pengaturan_page.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class FailingSettings extends FakeSettingsRepository {
  @override
  Future<void> setThemeMode(PicoThemeMode mode) async =>
      throw StateError('disk full');
}

Widget host(
  PengaturanBloc bloc, {
  Locale locale = const Locale('id'),
  ThemeData? theme,
  double scale = 1,
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
      body: BlocProvider.value(value: bloc, child: const PengaturanPage()),
    ),
  ),
);

PengaturanBloc make(
  FakeSettingsRepository s,
  FakeLocalDataAdmin a, {
  List<PicoLocale>? locales,
  DataUpdateAlerts alerts = const UnavailableDataUpdateAlerts(),
}) => PengaturanBloc(
  s,
  a,
  alerts,
  setLocale: (l) async => locales?.add(l),
  loadVersion: () async => (version: '8.0.0', build: '14'),
)..add(const PengaturanStarted());

void big(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'shows size, version, no notification row; options are labelled',
    (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
      big(tester);
      final h = tester.ensureSemantics();
      final admin = FakeLocalDataAdmin()..bytes = 12700000;
      await tester.pumpWidget(host(make(FakeSettingsRepository(), admin)));
      await tester.pumpAndSettle();
      expect(find.text('Ukuran: 12,1 MB'), findsOneWidget);
      expect(find.text('Versi 8.0.0 (14)'), findsOneWidget);
      expect(find.textContaining('Notifikasi'), findsNothing);
      expect(find.textContaining('Kabar pembaruan'), findsNothing);
      // The chosen option reads "..., dipilih"; the others do not.
      expect(find.bySemanticsLabel('Ikuti sistem, dipilih'), findsOneWidget);
      expect(find.bySemanticsLabel('Gelap'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Bahasa Indonesia, dipilih'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    },
  );

  testWidgets('theme change persists through the repository and is announced', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
    big(tester);
    final h = tester.ensureSemantics();
    final settings = FakeSettingsRepository();
    await tester.pumpWidget(host(make(settings, FakeLocalDataAdmin())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, PicoThemeMode.dark);
    expect(find.bySemanticsLabel('Gelap, dipilih'), findsOneWidget);
    expect(find.bySemanticsLabel('Ikuti sistem'), findsOneWidget);
    h.dispose();
  });

  testWidgets('language change goes through AppLocaleController port', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
    big(tester);
    final chosen = <PicoLocale>[];
    await tester.pumpWidget(
      host(
        make(FakeSettingsRepository(), FakeLocalDataAdmin(), locales: chosen),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(chosen, [PicoLocale.en]);
    expect(find.bySemanticsLabel('English'), findsNothing); // semantics off
  });

  testWidgets('clear: confirm dialog, then 0 B and the admin was called', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
    big(tester);
    final admin = FakeLocalDataAdmin()..bytes = 5000000;
    await tester.pumpWidget(host(make(FakeSettingsRepository(), admin)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PicoButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hapus data tersimpan?'), findsOneWidget);
    // Cancel keeps the data.
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(admin.clears, 0);
    await tester.tap(find.byType(PicoButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hapus data tersimpan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(admin.clears, 1);
    expect(find.text('Ukuran: 0 B'), findsOneWidget);
    expect(find.text('Data tersimpan dihapus.'), findsOneWidget);
  });

  testWidgets('a failed write keeps the old value and shows the toast', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
    big(tester);
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      host(make(FailingSettings(), FakeLocalDataAdmin())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan tidak tersimpan'), findsOneWidget);
    expect(find.bySemanticsLabel('Ikuti sistem, dipilih'), findsOneWidget);
    h.dispose();
  });

  testWidgets('english strings, and text scale 2.0 without overflow', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    big(tester);
    tester.view.physicalSize = const Size(412, 3200);
    await tester.pumpWidget(
      host(
        make(FakeSettingsRepository(), FakeLocalDataAdmin()..bytes = 2048),
        locale: const Locale('en'),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing); // title is in the shell
    expect(find.text('Follow system'), findsOneWidget);
    expect(find.text('Size: 2.0 KB'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
  });

  for (final (dark, scale) in [(false, 1.0), (true, 2.0)]) {
    final n = '${dark ? 'dark' : 'light'}_x${scale.toInt()}';
    testWidgets('golden $n', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
      tester.view.physicalSize = Size(412, scale == 2 ? 2600 : 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          make(
            FakeSettingsRepository(),
            FakeLocalDataAdmin()..bytes = 12700000,
          ),
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/pengaturan_$n.png'),
      );
    }, tags: ['golden']);
  }
}
