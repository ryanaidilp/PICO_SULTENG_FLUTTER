import 'package:consent_api/consent_api.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/push_notification_impl.dart';
import 'package:push_notification_impl/src/presentation/notification_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gate() extends Fake implements ConsentGate {
  final Map<ConsentPurpose, bool> granted = {};

  @override
  bool isGranted(ConsentPurpose purpose) => granted[purpose] ?? false;

  @override
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async => this.granted[purpose] = granted;
}

const _quietHours = Key('notification_settings.quiet_hours');
const _start = Key('notification_settings.quiet_hours.start');
const _end = Key('notification_settings.quiet_hours.end');
const _marketing = Key('notification_settings.marketing');

void main() {
  late _Gate gate;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeatureSDKRegistry.instance.clear();
    gate = _Gate();
    ConsentGateRegistry.instance.install(gate);
  });

  tearDown(ConsentGateRegistry.instance.reset);

  // A new SDK per pump, so what survives is what the SDK persisted.
  Future<PushNotificationSDK> pumpPage(WidgetTester tester) async {
    FeatureSDKRegistry.instance.clear();
    final sdk = PushNotificationSDKImpl.create(handlers: const []);
    await tester.pumpWidget(
      MaterialApp(
        theme: PicoTheme.light(),
        home: NotificationSettingsPage(sdk: sdk),
      ),
    );
    await tester.pumpAndSettle();
    return sdk;
  }

  bool switchValue(WidgetTester tester, Key key) =>
      tester.widget<SwitchListTile>(find.byKey(key)).value;

  testWidgets('quiet hours toggle writes the default window and clears it', (
    tester,
  ) async {
    final sdk = await pumpPage(tester);
    expect(switchValue(tester, _quietHours), isFalse);
    expect(find.byKey(_start), findsNothing);

    await tester.tap(find.byKey(_quietHours));
    await tester.pumpAndSettle();

    expect(
      await sdk.getQuietHours(),
      NotificationSettingsPage.defaultQuietHours,
    );
    expect(find.text('10:00 PM'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);

    await tester.tap(find.byKey(_quietHours));
    await tester.pumpAndSettle();

    expect(await sdk.getQuietHours(), isNull);
    expect(find.byKey(_start), findsNothing);
  });

  testWidgets('picking a time changes one end of the range', (tester) async {
    final sdk = await pumpPage(tester);
    await tester.tap(find.byKey(_quietHours));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_end));
    await tester.pumpAndSettle();
    // Switch the picker to text input and enter 6:30 (AM kept).
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '6');
    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      await sdk.getQuietHours(),
      const QuietHours(startMinute: 22 * 60, endMinute: 6 * 60 + 30),
    );
    expect(find.text('6:30 AM'), findsOneWidget);
  });

  testWidgets('marketing switch records the consent decision', (tester) async {
    gate.granted[ConsentPurpose.marketing] = true;
    final sdk = await pumpPage(tester);
    expect(switchValue(tester, _marketing), isTrue);

    await tester.tap(find.byKey(_marketing));
    await tester.pumpAndSettle();

    expect(gate.granted[ConsentPurpose.marketing], isFalse);
    expect(sdk.marketingEnabled, isFalse);
    expect(switchValue(tester, _marketing), isFalse);
  });

  testWidgets('settings persist through the SDK across page builds', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(_quietHours));
    await tester.tap(find.byKey(_marketing));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await pumpPage(tester);

    expect(switchValue(tester, _quietHours), isTrue);
    expect(find.text('10:00 PM'), findsOneWidget);
    expect(switchValue(tester, _marketing), isTrue);
  });

  test('declares the settings page config', () {
    FeatureSDKRegistry.instance.clear();
    final sdk = PushNotificationSDKImpl.create(handlers: const []);
    expect(sdk.pageConfigurations.values.map((c) => c.deeplinkPath), [
      PushNotificationSDK.settingsPath,
    ]);
  });
}
