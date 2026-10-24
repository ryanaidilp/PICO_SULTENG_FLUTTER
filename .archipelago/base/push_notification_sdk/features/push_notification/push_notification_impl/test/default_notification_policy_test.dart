import 'package:consent_api/consent_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/push_notification_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

PushNotification _message(String? tier, {String id = '1', String? sensitive}) =>
    PushNotification(
      id: id,
      receivedAt: DateTime.utc(2026),
      title: 'Paid 120.00',
      body: 'To account 1234',
      data: {'tier': ?tier, 'sensitive': ?sensitive},
    );

const _night = QuietHours(startMinute: 22 * 60, endMinute: 7 * 60);
const _marketingCap = NotificationCap(max: 3, window: Duration(days: 1));

NotificationDecision _decide(
  PushNotification notification, {
  DateTime? now,
  QuietHours? quietHours,
  List<DateTime> recent = const [],
  NotificationCap? cap,
  bool consent = true,
}) => DefaultNotificationPolicy.decide(
  notification: notification,
  now: now ?? DateTime(2026, 3, 4, 12),
  quietHours: quietHours,
  recentDeliveries: recent,
  cap: cap,
  marketingConsent: consent,
  lockScreenTitle: 'New notification',
  lockScreenBody: 'Open the app',
);

class _FakeDisplay() implements DeferredNotificationDisplay {
  final deferred = <(PushNotification, QuietHours)>[];
  bool accept = true;

  @override
  Future<bool> defer(PushNotification notification, QuietHours quietHours) {
    if (accept) deferred.add((notification, quietHours));
    return Future.value(accept);
  }
}

Matcher _suppressedBy(NotificationSuppression reason) =>
    isA<SuppressNotification>().having((d) => d.reason, 'reason', reason);

void main() {
  group('decide (pure)', () {
    test('critical passes quiet hours, missing consent and a full cap', () {
      final now = DateTime(2026, 3, 4, 23, 30);
      final decision = _decide(
        _message('critical'),
        now: now,
        quietHours: _night,
        recent: List.filled(10, now),
        cap: _marketingCap,
        consent: false,
      );
      expect(decision, isA<ShowNotification>());
    });

    test('marketing without consent is dropped', () {
      expect(
        _decide(_message('marketing'), consent: false),
        _suppressedBy(NotificationSuppression.noConsent),
      );
    });

    test('marketing inside quiet hours crossing midnight is dropped', () {
      for (final now in [
        DateTime(2026, 3, 4, 23),
        DateTime(2026, 3, 5, 6, 59),
      ]) {
        expect(
          _decide(_message('marketing'), now: now, quietHours: _night),
          _suppressedBy(NotificationSuppression.quietHours),
        );
      }
      expect(
        _decide(
          _message('marketing'),
          now: DateTime(2026, 3, 5, 7),
          quietHours: _night,
        ),
        isA<ShowNotification>(),
      );
    });

    test('transactional is not affected by quiet hours', () {
      expect(
        _decide(
          _message('transactional'),
          now: DateTime(2026, 3, 4, 23),
          quietHours: _night,
        ),
        isA<ShowNotification>(),
      );
    });

    test('cap counts only deliveries inside the window (rollover)', () {
      final now = DateTime.utc(2026, 3, 4, 12);
      final full = [
        now.subtract(const Duration(hours: 23)),
        now.subtract(const Duration(hours: 2)),
        now.subtract(const Duration(minutes: 1)),
      ];
      expect(
        _decide(
          _message('marketing'),
          now: now,
          recent: full,
          cap: _marketingCap,
        ),
        _suppressedBy(NotificationSuppression.capReached),
      );

      // The oldest one is exactly 24 h old: it has left the window.
      final rolled = [now.subtract(const Duration(days: 1)), ...full.skip(1)];
      expect(
        _decide(
          _message('marketing'),
          now: now,
          recent: rolled,
          cap: _marketingCap,
        ),
        isA<ShowNotification>(),
      );
    });

    test('an untagged message is shown unchanged (no redaction)', () {
      final shown = _decide(_message(null)) as ShowNotification;
      expect(shown.notification, _message(null));
      expect(shown.notification.publicTitle, isNull);
    });

    test('explicit sensitive tiers get generic lock-screen text', () {
      for (final tier in ['transactional', 'critical']) {
        final shown = _decide(_message(tier)) as ShowNotification;
        expect(shown.notification.publicTitle, 'New notification');
        expect(shown.notification.publicBody, 'Open the app');
        expect(shown.notification.title, 'Paid 120.00');
      }
    });

    test('data["sensitive"] == "true" opts in to redaction', () {
      for (final tier in [null, 'marketing']) {
        final shown =
            _decide(_message(tier, sensitive: 'true')) as ShowNotification;
        expect(shown.notification.publicTitle, 'New notification');
      }
      final plain = _decide(_message(null, sensitive: 'false'));
      expect((plain as ShowNotification).notification.publicTitle, isNull);
    });

    test('marketing is shown as-is', () {
      final shown = _decide(_message('marketing')) as ShowNotification;
      expect(shown.notification.publicTitle, isNull);
      expect(shown.notification, _message('marketing'));
    });

    group('Content{Safe,Detail} split (ADR-041)', () {
      PushNotification split(
        String? tier, {
        String? sensitive = 'true',
        String? title = 'New payment',
        String? body = 'Open the app to see it.',
        Map<String, String> detail = const {
          'detail_title': 'Paid 120.00',
          'detail_body': 'To account 1234',
        },
      }) => PushNotification(
        id: 'm-1',
        receivedAt: DateTime.utc(2026),
        title: title,
        body: body,
        data: {'nid': 'm-1', 'tier': ?tier, 'sensitive': ?sensitive, ...detail},
      );

      test('a sensitive message shows the detail; the sender text is the '
          'public text', () {
        for (final message in [
          split('critical', sensitive: null),
          split('transactional', sensitive: null),
          split(null),
          split('marketing'),
        ]) {
          final shown = _decide(message) as ShowNotification;
          expect(shown.notification.title, 'Paid 120.00');
          expect(shown.notification.body, 'To account 1234');
          expect(shown.notification.publicTitle, 'New payment');
          expect(shown.notification.publicBody, 'Open the app to see it.');
          expect(shown.notification.data, message.data);
        }
      });

      test('a non-sensitive message with detail keys is shown unchanged', () {
        for (final message in [
          split('marketing', sensitive: null),
          split(null, sensitive: null),
          split(null, sensitive: 'false'),
        ]) {
          final shown = _decide(message) as ShowNotification;
          expect(shown.notification, message);
          expect(shown.notification.publicTitle, isNull);
        }
      });

      test('missing sender text falls back to the generic text', () {
        final shown = _decide(
          split('critical', title: null, body: null),
        ) as ShowNotification;
        expect(shown.notification.title, 'Paid 120.00');
        expect(shown.notification.publicTitle, 'New notification');
        expect(shown.notification.publicBody, 'Open the app');
      });

      test('tier rules still run first', () {
        expect(
          _decide(split('marketing'), consent: false),
          _suppressedBy(NotificationSuppression.noConsent),
        );
      });

      test('without detail keys the output is unchanged', () {
        expect(
          (_decide(_message('critical')) as ShowNotification).notification,
          PushNotification(
            id: '1',
            receivedAt: DateTime.utc(2026),
            title: 'Paid 120.00',
            body: 'To account 1234',
            data: const {'tier': 'critical'},
            publicTitle: 'New notification',
            publicBody: 'Open the app',
          ),
        );
        expect(
          (_decide(_message(null)) as ShowNotification).notification,
          _message(null),
        );
      });
    });
  });

  group('evaluate (store, clock, consent injected)', () {
    late DateTime now;
    late DefaultNotificationPolicy policy;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      now = DateTime.utc(2026, 3, 4, 12);
      policy = DefaultNotificationPolicy(
        clock: () => now,
        isGranted: (purpose) => purpose == ConsentPurpose.marketing,
      );
    });

    test(
      'records shown deliveries and enforces the cap across the window',
      () async {
        Future<NotificationDecision> send() =>
            policy.evaluate(_message('marketing'));

        for (var i = 0; i < 3; i++) {
          expect(await send(), isA<ShowNotification>());
          now = now.add(const Duration(hours: 1));
        }
        expect(await send(), _suppressedBy(NotificationSuppression.capReached));

        // 24 h after the first delivery, one slot frees up.
        now = DateTime.utc(2026, 3, 5, 12);
        expect(await send(), isA<ShowNotification>());
        expect(await send(), _suppressedBy(NotificationSuppression.capReached));
      },
    );

    test('a concurrent burst cannot overshoot the cap', () async {
      final decisions = await Future.wait([
        for (var i = 0; i < 5; i++)
          policy.evaluate(_message('marketing', id: '$i')),
      ]);
      expect(decisions.whereType<ShowNotification>(), hasLength(3));
    });

    test('untagged messages are never capped or recorded', () async {
      final capped = DefaultNotificationPolicy(
        clock: () => now,
        caps: const {
          NotificationTier.transactional: NotificationCap(
            max: 1,
            window: Duration(days: 1),
          ),
        },
      );
      for (var i = 0; i < 3; i++) {
        expect(await capped.evaluate(_message(null)), isA<ShowNotification>());
      }
      // The explicit tier still has its full cap.
      expect(
        await capped.evaluate(_message('transactional')),
        isA<ShowNotification>(),
      );
      expect(
        await capped.evaluate(_message('transactional')),
        _suppressedBy(NotificationSuppression.capReached),
      );
    });

    test('reads quiet hours from the store', () async {
      await const NotificationPolicyStore().writeQuietHours(_night);
      now = DateTime(2026, 3, 4, 23);
      expect(
        await policy.evaluate(_message('marketing')),
        _suppressedBy(NotificationSuppression.quietHours),
      );
    });

    group('deferral', () {
      late _FakeDisplay display;

      setUp(() async {
        display = _FakeDisplay();
        policy = DefaultNotificationPolicy(
          clock: () => now,
          isGranted: (purpose) => purpose == ConsentPurpose.marketing,
          deferredDisplay: display,
        );
        await const NotificationPolicyStore().writeQuietHours(_night);
        now = DateTime(2026, 3, 4, 23);
      });

      test('marketing in quiet hours is deferred and counts against the '
          'cap', () async {
        expect(
          await policy.evaluate(_message('marketing')),
          _suppressedBy(NotificationSuppression.quietHours),
        );
        expect(display.deferred.single.$1, _message('marketing'));
        expect(display.deferred.single.$2, _night);
        expect(
          await const NotificationPolicyStore().readDeliveries(
            NotificationTier.marketing,
          ),
          hasLength(1),
        );
      });

      test(
        'a sensitive message is deferred with its lock-screen text',
        () async {
          await policy.evaluate(_message('marketing', sensitive: 'true'));
          expect(display.deferred.single.$1.publicTitle, 'New notification');
        },
      );

      test('no consent or a full cap is dropped, not deferred', () async {
        final noConsent = DefaultNotificationPolicy(
          clock: () => now,
          isGranted: (_) => false,
          deferredDisplay: display,
        );
        await noConsent.evaluate(_message('marketing'));
        for (var i = 0; i < 4; i++) {
          await policy.evaluate(_message('marketing', id: '$i'));
        }
        expect(display.deferred, hasLength(3));
      });

      test('a failed or missing display drops and records nothing', () async {
        display.accept = false;
        await policy.evaluate(_message('marketing'));
        await DefaultNotificationPolicy(
          clock: () => now,
          isGranted: (_) => true,
        ).evaluate(_message('marketing'));
        expect(
          await const NotificationPolicyStore().readDeliveries(
            NotificationTier.marketing,
          ),
          isEmpty,
        );
      });

      test('outside quiet hours nothing is deferred', () async {
        now = DateTime(2026, 3, 4, 12);
        expect(
          await policy.evaluate(_message('marketing')),
          isA<ShowNotification>(),
        );
        expect(display.deferred, isEmpty);
      });
    });

    test('defaults to the installed consent gate (fail closed)', () async {
      ConsentGateRegistry.instance.reset();
      final gated = DefaultNotificationPolicy(clock: () => now);
      expect(
        await gated.evaluate(_message('marketing')),
        _suppressedBy(NotificationSuppression.noConsent),
      );
    });
  });

  test('store round-trips and clears quiet hours', () async {
    SharedPreferences.setMockInitialValues({});
    const store = NotificationPolicyStore();
    expect(await store.readQuietHours(), isNull);
    await store.writeQuietHours(_night);
    expect(await store.readQuietHours(), _night);
    await store.writeQuietHours(null);
    expect(await store.readQuietHours(), isNull);
  });
}
