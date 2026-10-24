import 'package:consent_api/consent_api.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:push_notification_impl/push_notification_impl.dart';
import 'package:push_notification_impl/src/presentation/notification_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T29: the generated /notification-settings page (reached from Pengaturan as
/// "Atur notifikasi") meets the four guidelines at text scale 2.0, light and
/// dark. Our own test file: the generated tests stay untouched.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeatureSDKRegistry.instance.clear();
  });
  tearDown(ConsentGateRegistry.instance.reset);

  for (final dark in [false, true]) {
    testWidgets('guidelines at x2, ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(412, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sem = tester.ensureSemantics();
      final sdk = PushNotificationSDKImpl.create(handlers: const []);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PicoTheme.dark() : PicoTheme.light(),
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: w!,
          ),
          home: NotificationSettingsPage(sdk: sdk),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
      sem.dispose();
    });
  }
}
