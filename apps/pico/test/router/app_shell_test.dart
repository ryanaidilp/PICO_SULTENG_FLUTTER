import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identifiers/identifiers.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico/app.dart';
import 'package:pico/host/push/push_tap_router.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico/router/pico_tab_bar.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:router_registry/router_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers a stand-in page for every non-tab C07 path, as the feature
/// manifests will.
RouteRegistryImpl registryWithFeatures() {
  const tabs = {
    PicoRoutes.beranda,
    PicoRoutes.statistikRoot,
    PicoRoutes.layanan,
    PicoRoutes.info,
  };
  final registry = RouteRegistryImpl();
  var i = 0;
  registry.register([
    for (final p in PicoRoutes.patterns)
      if (!tabs.contains(p))
        AutoRoute(
          page: PageInfo.builder(
            'Stub${i++}Route',
            builder: (context, data) => Scaffold(body: Text('stub $p')),
          ),
          path: p,
        ),
  ]);
  return registry;
}

String concrete(String pattern) => pattern
    .replaceAll(':id', '7271')
    .replaceAll(':code', '7271')
    .replaceAll(':slug', 'cuci-tangan');

Future<AppRouter> pumpApp(
  WidgetTester tester, {
  RouteRegistry? registry,
  SettingsRepository? settings,
  double scale = 1,
  PushTapRouter? pushTaps,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() => LocaleSettings.setLocale(PicoLocale.id));
  final router = AppRouter(registry ?? registryWithFeatures());
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(412, 892),
        textScaler: TextScaler.linear(scale),
      ),
      child: PicoApp(
        router: router,
        settings: settings ?? FakeSettingsRepository(),
        pushTaps: pushTaps,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('every C07 path resolves against the built router', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    expect(router.currentPath, '/beranda');
    for (final pattern in PicoRoutes.patterns) {
      final path = concrete(pattern);
      await router.navigatePath(path);
      await tester.pumpAndSettle();
      expect(router.currentPath, path, reason: 'unmatched: $pattern');
    }
  });

  testWidgets('builders from PicoRoutes resolve too, with queries', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    for (final path in [
      PicoRoutes.statistik(level: 'province', id: '72', metric: 'positive'),
      PicoRoutes.provinsi('72'),
      PicoRoutes.kabupatenDetail(7271),
      PicoRoutes.rt(area: 'regency:7271'),
      PicoRoutes.peta(metric: 'active', date: DateTime(2024, 1, 14)),
      PicoRoutes.rumahSakitDetail('7271025'),
      PicoRoutes.infografisDetail(146, page: 1),
      PicoRoutes.tips('cuci-tangan'),
    ]) {
      await router.navigatePath(path);
      await tester.pumpAndSettle();
      expect(router.currentUrl, path);
    }
  });

  testWidgets('an unknown path redirects to /beranda', (tester) async {
    final router = await pumpApp(tester);
    await router.navigatePath('/tidak-ada/halaman');
    await tester.pumpAndSettle();
    expect(router.currentPath, '/beranda');
  });

  testWidgets(
    'the four tabs switch and keep their placeholder until a feature registers',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Halaman ini segera hadir.'), findsOneWidget);
      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman ini segera hadir.'), findsOneWidget);
      await tester.tap(find.text('Layanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      expect(find.byType(PicoTabBar), findsOneWidget);
    },
  );

  testWidgets('a feature route at a tab path becomes that tab root', (
    tester,
  ) async {
    final registry = RouteRegistryImpl()
      ..register([
        AutoRoute(
          page: PageInfo.builder(
            'HomeRoute',
            builder: (context, data) => const Text('Beranda fitur'),
          ),
          path: PicoRoutes.beranda,
        ),
      ]);
    await pumpApp(tester, registry: registry);
    expect(find.text('Beranda fitur'), findsOneWidget);
    expect(find.text('Halaman ini segera hadir.'), findsNothing);
  });

  testWidgets('the settings button opens /pengaturan', (tester) async {
    final router = await pumpApp(tester);
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expect(router.currentPath, PicoRoutes.pengaturan);
  });

  testWidgets('theme mode follows settings at once, no restart', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);
    ThemeMode mode() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(mode(), ThemeMode.system);
    await settings.setThemeMode(PicoThemeMode.dark);
    await tester.pump();
    expect(mode(), ThemeMode.dark);
    await settings.setThemeMode(PicoThemeMode.light);
    await tester.pump();
    expect(mode(), ThemeMode.light);
  });

  testWidgets('language switches at once and the choice is saved', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Beranda'), findsWidgets);
    await tester.runAsync(() => AppLocaleController.setLocale(PicoLocale.en));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    final prefs = await tester.runAsync(
      SharedPreferences.getInstance,
    ) as SharedPreferences;
    expect(prefs.getKeys(), isNotEmpty);
    await tester.runAsync(() => AppLocaleController.setLocale(PicoLocale.id));
  });

  testWidgets(
    'tab labels fit on one line at text scale 2.0 and never use an ellipsis',
    (tester) async {
      await pumpApp(tester, scale: 2);
      expect(tester.takeException(), isNull);
      final labels = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(PicoTabBar),
          matching: find.byType(Text),
        ),
      );
      expect(labels.length, 4);
      for (final t in labels) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, 1);
      }
    },
  );

  testWidgets('content is centred and at most 640 dp wide on a large screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => LocaleSettings.setLocale(PicoLocale.id));
    final router = AppRouter(registryWithFeatures());
    await tester.pumpWidget(
      PicoApp(router: router, settings: FakeSettingsRepository()),
    );
    await tester.pumpAndSettle();
    final box = tester.getRect(
      find
          .byType(ConstrainedBox)
          .evaluate()
          .map((e) => find.byWidget(e.widget))
          .firstWhere((f) {
            final w = tester.widget<ConstrainedBox>(f);
            return w.constraints.maxWidth == 640;
          }),
    );
    expect(box.width, lessThanOrEqualTo(640));
    expect(box.center.dx, closeTo(700, 1));
  });
}
