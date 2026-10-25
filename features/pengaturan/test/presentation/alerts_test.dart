import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengaturan/src/l10n/translations.g.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/testing.dart';

import 'pengaturan_page_test.dart' show big, host, make;

Future<void> open(
  WidgetTester tester,
  FakeSettingsRepository settings,
  FakeDataUpdateAlerts alerts, {
  Locale locale = const Locale('id'),
  double scale = 1,
  ThemeData? theme,
}) async {
  await tester.runAsync(
    () => LocaleSettings.setLocale(
      locale.languageCode == 'en' ? AppLocale.en : AppLocale.id,
    ),
  );
  big(tester);
  await tester.pumpWidget(
    host(
      make(settings, FakeLocalDataAdmin(), alerts: alerts),
      locale: locale,
      scale: scale,
      theme: theme,
    ),
  );
  await tester.pumpAndSettle();
}

/// PicoButton awaits the haptics channel (real I/O) before it calls onPressed.
Future<void> tapButton(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no push in the build: no notification row at all', (
    tester,
  ) async {
    await open(
      tester,
      FakeSettingsRepository(),
      FakeDataUpdateAlerts(available: false),
    );
    expect(find.text('Kabar pembaruan data'), findsNothing);
    expect(find.text('Notifikasi'), findsNothing);
  });

  testWidgets('fresh install: switch off, and the port is never asked', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts();
    await open(tester, FakeSettingsRepository(), alerts);
    expect(find.text('Kabar pembaruan data'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    // Opening the page neither enables nor queries the OS: no vendor call
    // before the user opts in.
    expect(alerts.calls, isEmpty);
    expect(find.text('Atur notifikasi'), findsNothing);
    expect(find.text('Buka pengaturan sistem'), findsNothing);
  });

  testWidgets('switch on shows the explain sheet; "Nanti saja" does nothing', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts();
    final settings = FakeSettingsRepository();
    await open(tester, settings, alerts);
    await tester.tap(find.text('Kabar pembaruan data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OneSignal'), findsOneWidget);
    expect(find.textContaining('ID perangkat'), findsOneWidget);
    expect(find.textContaining('Tidak ada iklan'), findsOneWidget);
    expect(alerts.calls, isEmpty);
    await tapButton(
      tester,
      find.widgetWithText(PicoButton, 'Nanti saja').first,
    );
    await tester.pumpAndSettle();
    expect(alerts.calls, isEmpty);
    expect(settings.dataUpdateAlertsWanted, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('Izinkan: enable runs, the switch stays on, Atur appears', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts();
    final settings = FakeSettingsRepository();
    await open(tester, settings, alerts);
    await tester.tap(find.text('Kabar pembaruan data'));
    await tester.pumpAndSettle();
    await tapButton(tester, find.widgetWithText(PicoButton, 'Izinkan').first);
    await tester.pumpAndSettle();
    expect(alerts.calls, ['enable']);
    expect(settings.dataUpdateAlertsWanted, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('Atur notifikasi'), findsOneWidget);
  });

  testWidgets('OS refusal: switch back to off, system settings row shows', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts(
      outcome: DataUpdateAlertsOutcome.denied,
    );
    final settings = FakeSettingsRepository();
    await open(tester, settings, alerts);
    await tester.tap(find.text('Kabar pembaruan data'));
    await tester.pumpAndSettle();
    await tapButton(tester, find.widgetWithText(PicoButton, 'Izinkan').first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(settings.dataUpdateAlertsWanted, isFalse);
    expect(find.text('Buka pengaturan sistem'), findsOneWidget);
    expect(find.text('Atur notifikasi'), findsNothing);
    await tester.tap(find.text('Buka pengaturan sistem'));
    await tester.pumpAndSettle();
    expect(alerts.calls, ['enable', 'settings']);
  });

  testWidgets('switch off: disable runs and the wish is saved as off', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts(permission: true);
    final settings = FakeSettingsRepository();
    await settings.setDataUpdateAlertsWanted(true);
    await open(tester, settings, alerts);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.text('Kabar pembaruan data'));
    await tester.pumpAndSettle();
    expect(alerts.calls, ['permission', 'disable']);
    expect(settings.dataUpdateAlertsWanted, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('wanted but OS permission revoked: off with the settings row', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts();
    final settings = FakeSettingsRepository();
    await settings.setDataUpdateAlertsWanted(true);
    await open(tester, settings, alerts);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Buka pengaturan sistem'), findsOneWidget);
  });

  testWidgets('a service failure keeps the switch off and shows the toast', (
    tester,
  ) async {
    final alerts = FakeDataUpdateAlerts(
      outcome: DataUpdateAlertsOutcome.failed,
    );
    await open(tester, FakeSettingsRepository(), alerts);
    await tester.tap(find.text('Kabar pembaruan data'));
    await tester.pumpAndSettle();
    await tapButton(tester, find.widgetWithText(PicoButton, 'Izinkan').first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Pengaturan tidak tersimpan'), findsOneWidget);
  });

  testWidgets('semantics: one toggle node, labelled, state read, 48 dp', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    final settings = FakeSettingsRepository();
    await settings.setDataUpdateAlertsWanted(true);
    await open(tester, settings, FakeDataUpdateAlerts(permission: true));
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Kabar pembaruan data')),
    );
    expect(node, containsSemantics(hasToggledState: true, isToggled: true));
    expect(node.label, contains('Kabar saat data baru tersedia'));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
    h.dispose();
  });

  testWidgets('english, text scale 2.0, denied state: no overflow', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await settings.setDataUpdateAlertsWanted(true);
    await open(
      tester,
      settings,
      FakeDataUpdateAlerts(),
      locale: const Locale('en'),
      scale: 2,
      theme: PicoTheme.dark(),
    );
    tester.view.physicalSize = const Size(412, 3600);
    await tester.pumpAndSettle();
    expect(find.text('Data update alerts'), findsOneWidget);
    expect(find.text('Open system settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final sem = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(picoTextContrastGuideline));
    sem.dispose();
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.id));
  });
}
