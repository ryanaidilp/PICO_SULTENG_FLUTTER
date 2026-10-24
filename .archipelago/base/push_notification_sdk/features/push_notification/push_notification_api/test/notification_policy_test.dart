import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_api/push_notification_api.dart';

void main() {
  DateTime at(int hour, int minute) => DateTime(2026, 3, 4, hour, minute);

  group('NotificationTier', () {
    test('parses known names', () {
      expect(NotificationTier.parse('critical'), NotificationTier.critical);
      expect(NotificationTier.parse('marketing'), NotificationTier.marketing);
    });

    test('unknown or missing parses as transactional', () {
      expect(NotificationTier.parse(null), NotificationTier.transactional);
      expect(NotificationTier.parse('promo'), NotificationTier.transactional);
      expect(NotificationTier.transactional.sensitive, isTrue);
      expect(NotificationTier.marketing.sensitive, isFalse);
    });

    test('PushNotification.tier reads data["tier"]', () {
      final notification = PushNotification(
        id: '1',
        receivedAt: DateTime.utc(2026),
        data: const {'tier': 'critical'},
      );
      expect(notification.tier, NotificationTier.critical);
    });

    test('redaction is opt-in: untagged is not sensitive', () {
      PushNotification of(Map<String, String> data) =>
          PushNotification(id: '1', receivedAt: DateTime.utc(2026), data: data);

      expect(of(const {}).tagged, isFalse);
      expect(of(const {}).sensitive, isFalse);
      expect(of(const {'tier': 'promo'}).sensitive, isFalse);
      expect(of(const {'tier': 'transactional'}).sensitive, isTrue);
      expect(of(const {'tier': 'critical'}).sensitive, isTrue);
      expect(of(const {'tier': 'marketing'}).sensitive, isFalse);
      expect(of(const {'sensitive': 'true'}).sensitive, isTrue);
    });
  });

  group('QuietHours.contains', () {
    test('same-day window is start inclusive, end exclusive', () {
      const window = QuietHours(startMinute: 13 * 60, endMinute: 14 * 60);
      expect(window.contains(at(12, 59)), isFalse);
      expect(window.contains(at(13, 0)), isTrue);
      expect(window.contains(at(14, 0)), isFalse);
    });

    test('window crossing midnight', () {
      const window = QuietHours(startMinute: 22 * 60, endMinute: 7 * 60);
      expect(window.contains(at(21, 59)), isFalse);
      expect(window.contains(at(22, 0)), isTrue);
      expect(window.contains(at(0, 0)), isTrue);
      expect(window.contains(at(6, 59)), isTrue);
      expect(window.contains(at(7, 0)), isFalse);
    });

    test('start == end is an empty window', () {
      const window = QuietHours(startMinute: 600, endMinute: 600);
      expect(window.contains(at(10, 0)), isFalse);
    });
  });

  test('registry shows everything until a policy is installed', () async {
    NotificationPolicyRegistry.instance.reset();
    final notification = PushNotification(id: '1', receivedAt: DateTime(2026));
    final decision = await NotificationPolicyRegistry.instance.policy.evaluate(
      notification,
    );
    expect(decision, isA<ShowNotification>());
    expect((decision as ShowNotification).notification, notification);
  });

  test('registry drops deferred messages until a display is installed', () {
    NotificationPolicyRegistry.instance.reset();
    expect(
      NotificationPolicyRegistry.instance.deferredDisplay.defer(
        PushNotification(id: '1', receivedAt: DateTime(2026)),
        const QuietHours(startMinute: 0, endMinute: 60),
      ),
      completion(isFalse),
    );
  });
}
