import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico/host/push/push_data_update_alerts.dart';
import 'package:pico/host/push/push_tap_router.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:push_notification_api/push_notification_api.dart';

import '../../router/app_shell_test.dart' show concrete, pumpApp;

/// Records every call on the push contract, in order.
class FakeSdk implements PushNotificationSDK {
  FakeSdk({
    this.providers = const {PushNotificationProvider.oneSignal},
    this.permission = PushNotificationPermission.granted,
  });

  final Set<PushNotificationProvider> providers;
  PushNotificationPermission permission;
  String? failOn;
  final calls = <String>[];

  void _log(String call) {
    calls.add(call);
    if (failOn == call) throw StateError('fake failure on $call');
  }

  @override
  Set<PushNotificationProvider> get availableProviders => providers;

  @override
  Future<PushNotificationPermission> requestPermission() async {
    _log('requestPermission');
    return permission;
  }

  @override
  Future<PushNotificationPermission> getPermissionStatus() async {
    _log('getPermissionStatus');
    return permission;
  }

  @override
  Future<void> setMarketingEnabled({required bool enabled}) async =>
      _log('consent:$enabled');

  @override
  Future<void> subscribeToTopic(String topic) async => _log('subscribe:$topic');

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      _log('unsubscribe:$topic');

  @override
  Future<void> clearAll() async => _log('clearAll');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

PushNotification notification(String? route) =>
    PushNotification(id: 'n', receivedAt: DateTime(2026), route: route);

void main() {
  group('PushDataUpdateAlerts (ADR-0112)', () {
    test('no App ID: unavailable, and never touches the vendor', () async {
      final sdk = FakeSdk();
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: '  ');
      expect(alerts.available, isFalse);
      expect(await alerts.enable(), DataUpdateAlertsOutcome.failed);
      expect(sdk.calls, isEmpty);
    });

    test('no OneSignal provider wired: unavailable', () {
      final alerts = PushDataUpdateAlerts(
        sdk: FakeSdk(providers: {}),
        appId: 'abc',
      );
      expect(alerts.available, isFalse);
    });

    test('creating and reading availability makes no vendor call', () {
      final sdk = FakeSdk();
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      expect(alerts.available, isTrue);
      expect(sdk.calls, isEmpty);
    });

    test('enable: consent, then OS permission, then the topic', () async {
      final sdk = FakeSdk();
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      expect(await alerts.enable(), DataUpdateAlertsOutcome.enabled);
      expect(sdk.calls, [
        'consent:true',
        'requestPermission',
        'subscribe:data_update',
      ]);
    });

    test('OS refusal: consent is taken back, no topic', () async {
      final sdk = FakeSdk(permission: PushNotificationPermission.denied);
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      expect(await alerts.enable(), DataUpdateAlertsOutcome.denied);
      expect(sdk.calls, ['consent:true', 'requestPermission', 'consent:false']);
    });

    test('a vendor failure revokes consent and reports failure', () async {
      final sdk = FakeSdk()..failOn = 'subscribe:data_update';
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      expect(await alerts.enable(), DataUpdateAlertsOutcome.failed);
      expect(sdk.calls.last, 'consent:false');
    });

    test('disable: unsubscribe, opt out, revoke; all run on failure', () async {
      final sdk = FakeSdk()..failOn = 'unsubscribe:data_update';
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      await expectLater(alerts.disable, throwsStateError);
      expect(sdk.calls, [
        'unsubscribe:data_update',
        'clearAll',
        'consent:false',
      ]);
    });

    test('permission status is read without prompting', () async {
      final sdk = FakeSdk(permission: PushNotificationPermission.denied);
      final alerts = PushDataUpdateAlerts(sdk: sdk, appId: 'abc');
      expect(await alerts.osPermissionGranted(), isFalse);
      expect(sdk.calls, ['getPermissionStatus']);
    });

    test('openSystemSettings calls the injected opener', () async {
      var opened = 0;
      final alerts = PushDataUpdateAlerts(
        sdk: FakeSdk(),
        appId: 'abc',
        openSettings: () async => opened++,
      );
      await alerts.openSystemSettings();
      expect(opened, 1);
    });
  });

  group('resolvePushRoute (C07)', () {
    test('every C07 pattern with concrete ids is kept', () {
      for (final pattern in PicoRoutes.patterns) {
        final path = concrete(pattern);
        expect(resolvePushRoute(path), path, reason: pattern);
      }
    });

    test('queries are kept', () {
      const path = '/statistik?level=province&id=72&metric=positive';
      expect(resolvePushRoute(path), path);
    });

    test('unknown, missing or foreign routes open Beranda', () {
      for (final route in [
        null,
        '',
        'statistik',
        '/tidak-ada',
        '/statistik/kabupaten/7271/extra',
        'https://example.com/statistik',
        '//evil.example/statistik',
        '/statistik/%',
      ]) {
        expect(resolvePushRoute(route), PicoRoutes.beranda, reason: '$route');
      }
    });
  });

  group('PushTapRouter', () {
    test('a cold-start tap waits for attach, then opens once', () async {
      final taps = StreamController<PushNotification>.broadcast();
      final router = PushTapRouter(taps.stream);
      addTearDown(router.dispose);
      taps.add(notification('/statistik/kabupaten/7271'));
      await Future<void>.delayed(Duration.zero);
      final opened = <String>[];
      router.attach(opened.add);
      expect(opened, ['/statistik/kabupaten/7271']);
      router.attach(opened.add);
      expect(opened, hasLength(1));
      taps.add(notification('/peta'));
      await Future<void>.delayed(Duration.zero);
      expect(opened.last, '/peta');
    });

    test('a tap while detached is kept for the next attach', () async {
      final taps = StreamController<PushNotification>.broadcast();
      final router = PushTapRouter(taps.stream)..attach((_) {});
      addTearDown(router.dispose);
      router.detach();
      taps.add(notification(null));
      await Future<void>.delayed(Duration.zero);
      final opened = <String>[];
      router.attach(opened.add);
      expect(opened, [PicoRoutes.beranda]);
    });
  });

  group('tap routing in the app', () {
    testWidgets('a tap in the background opens the route', (tester) async {
      final taps = StreamController<PushNotification>.broadcast();
      final taprouter = PushTapRouter(taps.stream);
      addTearDown(taprouter.dispose);
      final router = await pumpApp(tester, pushTaps: taprouter);
      expect(router.currentPath, '/beranda');
      taps.add(notification('/statistik/kabupaten/7271'));
      await tester.pumpAndSettle();
      expect(router.currentPath, '/statistik/kabupaten/7271');
    });

    testWidgets('a cold-start tap (before the app) is the first route', (
      tester,
    ) async {
      final taps = StreamController<PushNotification>.broadcast();
      final taprouter = PushTapRouter(taps.stream);
      addTearDown(taprouter.dispose);
      taps.add(notification('/statistik/kabupaten/7271'));
      await tester.pump();
      final router = await pumpApp(tester, pushTaps: taprouter);
      expect(router.currentPath, '/statistik/kabupaten/7271');
    });

    testWidgets('an unknown route opens Beranda', (tester) async {
      final taps = StreamController<PushNotification>.broadcast();
      final taprouter = PushTapRouter(taps.stream);
      addTearDown(taprouter.dispose);
      final router = await pumpApp(tester, pushTaps: taprouter);
      await router.navigatePath(PicoRoutes.info);
      await tester.pumpAndSettle();
      taps.add(notification('/halaman-yang-tidak-ada'));
      await tester.pumpAndSettle();
      expect(router.currentPath, '/beranda');
    });
  });
}
