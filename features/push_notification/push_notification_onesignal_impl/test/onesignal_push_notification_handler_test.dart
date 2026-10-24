import 'dart:async';

import 'package:consent_api/consent_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_onesignal_impl/src/onesignal_config.dart';
import 'package:push_notification_onesignal_impl/src/onesignal_push_notification_handler.dart';

class _MarketingGate() implements ConsentGate {
  final changesController = StreamController<ConsentState>.broadcast();

  @override
  ConsentState get state => const ConsentState.undecided();

  @override
  bool isGranted(ConsentPurpose purpose) => purpose == ConsentPurpose.marketing;

  @override
  Stream<ConsentState> get changes => changesController.stream;

  @override
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async {}

  @override
  Future<void> recordAll(
    Map<ConsentPurpose, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async {}

  @override
  Future<void> revokeAll({
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
  }) async {}

  @override
  Future<void> clear() async {}
}

/// Drops explicit transactional; redacts what `sensitive` opts in, like the
/// default policy; shows the rest unchanged.
class const _FakePolicy() implements NotificationPolicy {
  @override
  Future<NotificationDecision> evaluate(PushNotification notification) async {
    if (notification.data['tier'] == 'transactional') {
      return const SuppressNotification(NotificationSuppression.capReached);
    }
    if (!notification.sensitive) return ShowNotification(notification);
    return ShowNotification(
      PushNotification(
        id: notification.id,
        receivedAt: notification.receivedAt,
        publicTitle: 'New notification',
      ),
    );
  }
}

/// Records each input and applies the ADR-041 split to sensitive messages
/// like the default policy: detail in the app, the sender's text on the lock
/// screen.
class _SplitPolicy() implements NotificationPolicy {
  final inputs = <PushNotification>[];

  @override
  Future<NotificationDecision> evaluate(PushNotification notification) async {
    inputs.add(notification);
    if (!notification.sensitive) return ShowNotification(notification);
    return ShowNotification(
      PushNotification(
        id: notification.id,
        receivedAt: notification.receivedAt,
        title: notification.data['detail_title'],
        body: notification.data['detail_body'],
        data: notification.data,
        publicTitle: notification.title,
        publicBody: notification.body,
      ),
    );
  }
}

const _config = OneSignalConfig(
  appId: 'YOUR_ONESIGNAL_APP_ID',
  consentPurpose: ConsentPurpose.marketing,
);

/// (channel, call) in arrival order.
typedef _Call = ({String channel, MethodCall call});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channels = [
    'OneSignal',
    'OneSignal#notifications',
    'OneSignal#user',
    'OneSignal#pushsubscription',
    'OneSignal#inappmessages',
  ];
  final calls = <_Call>[];
  var failInitialize = false;

  int indexOf(String method) =>
      calls.indexWhere((c) => c.call.method == method);

  late _MarketingGate gate;

  setUp(() {
    calls.clear();
    failInitialize = false;
    gate = _MarketingGate();
    ConsentGateRegistry.instance.install(gate);
    for (final name in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async {
            calls.add((channel: name, call: call));
            if (call.method == 'OneSignal#initialize' && failInitialize) {
              throw PlatformException(code: 'init_failed');
            }
            // Non-nullable plugin results: permission, requestPermission.
            return switch (call.method) {
              'OneSignal#permission' => false,
              'OneSignal#requestPermission' => true,
              _ => null,
            };
          });
    }
  });

  tearDown(() {
    ConsentGateRegistry.instance.reset();
    NotificationPolicyRegistry.instance.reset();
    for (final name in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  test('consentRequired(true) runs before initialize', () async {
    final handler = OneSignalPushNotificationHandler(_config);
    await handler.getPermissionStatus();

    final required = indexOf('OneSignal#consentRequired');
    expect(required, isNonNegative);
    expect(calls[required].call.arguments, {'required': true});
    expect(required, lessThan(indexOf('OneSignal#initialize')));
  });

  test('initialize receives the app id, then consentGiven follows', () async {
    final handler = OneSignalPushNotificationHandler(_config);
    await handler.getPermissionStatus();

    final init = calls[indexOf('OneSignal#initialize')];
    expect(init.call.arguments, {'appId': 'YOUR_ONESIGNAL_APP_ID'});
    final given = indexOf('OneSignal#consentGiven');
    expect(given, greaterThan(indexOf('OneSignal#initialize')));
    expect(calls[given].call.arguments, {'granted': true});
  });

  test('the configured consent purpose feeds consentGiven', () async {
    final handler = OneSignalPushNotificationHandler(
      const OneSignalConfig(
        appId: 'x',
        consentPurpose: ConsentPurpose.diagnostics,
      ),
    );
    await handler.getPermissionStatus();

    // The test gate grants only marketing.
    expect(calls[indexOf('OneSignal#consentGiven')].call.arguments, {
      'granted': false,
    });
  });

  test('a null consent purpose starts OneSignal without a gate', () async {
    final handler = OneSignalPushNotificationHandler(
      const OneSignalConfig(appId: 'x', consentPurpose: null),
    );
    await handler.getPermissionStatus();

    expect(indexOf('OneSignal#consentRequired'), -1);
    expect(indexOf('OneSignal#consentGiven'), -1);
    expect(calls[indexOf('OneSignal#initialize')].call.arguments, {
      'appId': 'x',
    });
  });

  test('an empty app id leaves OneSignal off (no native call at all)', () async {
    final handler = OneSignalPushNotificationHandler(
      const OneSignalConfig(
        appId: '',
        consentPurpose: ConsentPurpose.marketing,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(handler.provider, PushNotificationProvider.oneSignal);
    expect(calls, isEmpty);
  });

  test('initialize runs before requestPermission', () async {
    final handler = OneSignalPushNotificationHandler(_config);
    final result = await handler.requestPermission();

    expect(result, PushNotificationPermission.granted);
    expect(
      indexOf('OneSignal#initialize'),
      lessThan(indexOf('OneSignal#requestPermission')),
    );
  });

  test('a failed init is logged, not rethrown', () async {
    failInitialize = true;
    final handler = OneSignalPushNotificationHandler(_config);

    await expectLater(handler.getPermissionStatus(), completes);
    await expectLater(handler.requestPermission(), completes);
    await expectLater(handler.getToken(), completion(isNull));
  });

  test('a later consent change calls consentGiven', () async {
    final handler = OneSignalPushNotificationHandler(_config);
    await handler.getPermissionStatus();
    calls.clear();

    gate.changesController.add(
      const ConsentState.undecided().withDecision(
        ConsentDecision(
          purpose: ConsentPurpose.marketing,
          granted: false,
          recordedAt: DateTime.utc(2026),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final given = indexOf('OneSignal#consentGiven');
    expect(given, isNonNegative);
    expect(calls[given].call.arguments, {'granted': false});
  });

  test('foreground messages go through the policy before display', () async {
    NotificationPolicyRegistry.instance.install(const _FakePolicy());
    final handler = OneSignalPushNotificationHandler(_config);
    await handler.getPermissionStatus();
    final emitted = <PushNotification>[];
    final subscription = handler.foregroundStream.listen(emitted.add);
    calls.clear();

    for (final (id, data) in [
      ('m', {'tier': 'marketing'}),
      ('c', {'tier': 'critical'}),
      ('t', {'tier': 'transactional'}),
      ('u', <String, String>{}),
      ('s', {'sensitive': 'true'}),
    ]) {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'OneSignal#notifications',
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('OneSignal#onWillDisplayNotification', {
                'notification': {
                  'notificationId': id,
                  'title': 'Title',
                  'additionalData': data,
                },
              }),
            ),
            (_) {},
          );
    }
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    // OneSignal's listener list is static, so handlers from earlier tests
    // see the same events: compare as sets.
    Set<Object?> idsOf(String method) => {
      for (final c in calls)
        if (c.call.method == method)
          (c.call.arguments as Map)['notificationId'],
    };
    expect(idsOf('OneSignal#preventDefault'), {'m', 'c', 't', 'u', 's'});
    // Non-sensitive shown messages keep the OS banner; untagged ones are
    // unchanged from before the policy existed.
    expect(idsOf('OneSignal#displayNotification'), {'m', 'u'});
    expect(emitted.map((n) => n.id), ['m', 'c', 'u', 's']);
    expect(emitted.singleWhere((n) => n.id == 'u').title, 'Title');
    expect(emitted.singleWhere((n) => n.id == 'u').publicTitle, isNull);
  });

  test('a split message reaches the policy with its safe text and detail '
      'keys, and gets no OS banner', () async {
    final policy = _SplitPolicy();
    NotificationPolicyRegistry.instance.install(policy);
    final handler = OneSignalPushNotificationHandler(_config);
    await handler.getPermissionStatus();
    final emitted = <PushNotification>[];
    final subscription = handler.foregroundStream.listen(emitted.add);
    calls.clear();

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'OneSignal#notifications',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('OneSignal#onWillDisplayNotification', {
              'notification': {
                'notificationId': 'd',
                'title': 'New payment',
                'body': 'Open the app to see it.',
                'additionalData': {
                  'tier': 'transactional',
                  'sensitive': 'true',
                  'detail_title': 'Paid 120.00',
                  'detail_body': 'To account 1234',
                },
              },
            }),
          ),
          (_) {},
        );
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    final input = policy.inputs.firstWhere((n) => n.id == 'd');
    expect(input.title, 'New payment');
    expect(input.body, 'Open the app to see it.');
    expect(input.data['detail_title'], 'Paid 120.00');
    expect(input.data['detail_body'], 'To account 1234');
    expect(
      calls.where((c) => c.call.method == 'OneSignal#displayNotification'),
      isEmpty,
    );
    final shown = emitted.singleWhere((n) => n.id == 'd');
    expect(shown.title, 'Paid 120.00');
    expect(shown.publicTitle, 'New payment');
  });
}
