import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_api/push_notification_api.dart';

void main() {
  group('PushNotificationProvider', () {
    test('has two variants', () {
      expect(PushNotificationProvider.values.length, 2);
      expect(
        PushNotificationProvider.values,
        containsAll([
          PushNotificationProvider.fcm,
          PushNotificationProvider.oneSignal,
        ]),
      );
    });
  });

  group('PushNotificationPermission', () {
    test('has four variants', () {
      expect(PushNotificationPermission.values.length, 4);
      expect(
        PushNotificationPermission.values,
        containsAll([
          PushNotificationPermission.granted,
          PushNotificationPermission.denied,
          PushNotificationPermission.provisional,
          PushNotificationPermission.notDetermined,
        ]),
      );
    });
  });

  group('PushNotification', () {
    test('equality compares all fields', () {
      final now = DateTime.utc(2026, 2, 3);
      final a = PushNotification(
        id: 'msg-1',
        title: 'Hello',
        body: 'World',
        route: '/home',
        data: const {'key': 'value'},
        receivedAt: now,
      );
      final b = PushNotification(
        id: 'msg-1',
        title: 'Hello',
        body: 'World',
        route: '/home',
        data: const {'key': 'value'},
        receivedAt: now,
      );
      expect(a, equals(b));
    });

    test('inequality when id differs', () {
      final now = DateTime.utc(2026, 2, 3);
      final a = PushNotification(id: 'msg-1', receivedAt: now);
      final b = PushNotification(id: 'msg-2', receivedAt: now);
      expect(a, isNot(equals(b)));
    });

    test('route defaults to null', () {
      final n = PushNotification(id: 'x', receivedAt: DateTime.utc(2026, 2, 3));
      expect(n.route, isNull);
    });

    test('data defaults to empty map', () {
      final n = PushNotification(id: 'x', receivedAt: DateTime.utc(2026, 2, 3));
      expect(n.data, isEmpty);
    });
  });

  group('PushToken', () {
    test('equality compares all fields', () {
      final now = DateTime.utc(2026, 2, 3);
      final a = PushToken(
        provider: PushNotificationProvider.fcm,
        token: 'tok-abc',
        updatedAt: now,
      );
      final b = PushToken(
        provider: PushNotificationProvider.fcm,
        token: 'tok-abc',
        updatedAt: now,
      );
      expect(a, equals(b));
    });

    test('inequality when token differs', () {
      final now = DateTime.utc(2026, 2, 3);
      final a = PushToken(
        provider: PushNotificationProvider.fcm,
        token: 'tok-1',
        updatedAt: now,
      );
      final b = PushToken(
        provider: PushNotificationProvider.fcm,
        token: 'tok-2',
        updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
