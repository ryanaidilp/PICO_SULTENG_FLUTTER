import 'package:consent_api/consent_api.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/src/policy/notification_policy_store.dart';

/// At most `max` shown messages of a tier in any rolling `window`.
class const NotificationCap({
  required final int max,
  required final Duration window,
});

/// The generated app's [NotificationPolicy]: tiers, marketing consent,
/// quiet hours, caps and lock-screen-safe text. See ADR-037.
///
/// A sensitive message with `data['detail_title']` or `data['detail_body']`
/// is split by its sender (ADR-041): the app shows the detail text, and the
/// sender's title and body become `publicTitle` / `publicBody`. Detail keys
/// on a non-sensitive message are ignored.
///
/// `caps` maps tiers to a cap (missing means uncapped; critical and untagged
/// messages are never capped). Redaction is opt-in, see
/// `PushNotification.sensitive`. `isGranted` defaults to the installed
/// `ConsentGate`, read on every call. Pass localized `lockScreenTitle` /
/// `lockScreenBody`.
///
/// Marketing held back by quiet hours goes to `deferredDisplay` (default: the
/// registry's, which drops it unless a display package is installed) when it
/// would pass every other rule. A deferred message counts against the cap
/// now, not when it is shown.
class DefaultNotificationPolicy({
  final NotificationPolicyStore store = const NotificationPolicyStore(),
  final DateTime Function() clock = DateTime.now,
  final bool Function(ConsentPurpose purpose)? isGranted,
  final Map<NotificationTier, NotificationCap> caps = defaultCaps,
  final String lockScreenTitle = 'New notification',
  final String lockScreenBody = 'Open the app to see the details.',
  final DeferredNotificationDisplay? deferredDisplay,
}) implements NotificationPolicy {
  /// Marketing: 3 per 24 hours. Other tiers are uncapped.
  static const Map<NotificationTier, NotificationCap> defaultCaps = {
    NotificationTier.marketing: NotificationCap(
      max: 3,
      window: Duration(days: 1),
    ),
  };

  Future<void> _tail = Future.value();

  /// The rules, as a pure function. [recentDeliveries] are the tier's past
  /// shown times; only those inside the cap window count.
  static NotificationDecision decide({
    required PushNotification notification,
    required DateTime now,
    required QuietHours? quietHours,
    required List<DateTime> recentDeliveries,
    required NotificationCap? cap,
    required bool marketingConsent,
    required String lockScreenTitle,
    required String lockScreenBody,
  }) {
    final tier = notification.tier;
    if (tier != NotificationTier.critical) {
      if (tier == NotificationTier.marketing) {
        if (!marketingConsent) {
          return const SuppressNotification(NotificationSuppression.noConsent);
        }
        if (quietHours != null && quietHours.contains(now)) {
          return const SuppressNotification(NotificationSuppression.quietHours);
        }
      }
      if (cap != null &&
          _inWindow(recentDeliveries, now, cap.window).length >= cap.max) {
        return const SuppressNotification(NotificationSuppression.capReached);
      }
    }
    if (!notification.sensitive) return ShowNotification(notification);
    // Content{Safe,Detail} split (ADR-041): the sender put the full text in
    // data and the lock-screen-safe text in the visible title and body.
    final detailTitle = notification.data['detail_title'];
    final detailBody = notification.data['detail_body'];
    final split = detailTitle != null || detailBody != null;
    return ShowNotification(
      PushNotification(
        id: notification.id,
        receivedAt: notification.receivedAt,
        title: detailTitle ?? notification.title,
        body: detailBody ?? notification.body,
        route: notification.route,
        data: notification.data,
        publicTitle: split
            ? notification.title ?? lockScreenTitle
            : lockScreenTitle,
        publicBody: split
            ? notification.body ?? lockScreenBody
            : lockScreenBody,
      ),
    );
  }

  @override
  Future<NotificationDecision> evaluate(PushNotification notification) {
    // Serialised so a burst cannot read the same count and overshoot a cap.
    final result = _tail.then((_) => _evaluate(notification));
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<NotificationDecision> _evaluate(PushNotification notification) async {
    final now = clock();
    final tier = notification.tier;
    // Untagged messages keep the pre-policy behaviour: never capped.
    final cap = tier == NotificationTier.critical || !notification.tagged
        ? null
        : caps[tier];
    // A storage failure must not drop the message: consent, tiers and
    // redaction still apply, only quiet hours and caps are skipped.
    final recent = cap == null
        ? const <DateTime>[]
        : _inWindow(
            await _orElse(() => store.readDeliveries(tier), const []),
            now,
            cap.window,
          );
    final quietHours = await _orElse(store.readQuietHours, null);
    NotificationDecision decideWith(QuietHours? window) => decide(
      notification: notification,
      now: now,
      quietHours: window,
      recentDeliveries: recent,
      cap: cap,
      marketingConsent: (isGranted ?? ConsentGateRegistry.instance.isGranted)(
        ConsentPurpose.marketing,
      ),
      lockScreenTitle: lockScreenTitle,
      lockScreenBody: lockScreenBody,
    );
    final decision = decideWith(quietHours);
    var record = decision is ShowNotification;
    // Deferral: what the message would get outside quiet hours. Consent,
    // cap and redaction still apply.
    if (decision
        case SuppressNotification(reason: NotificationSuppression.quietHours)
        when quietHours != null) {
      if (decideWith(null) case ShowNotification(:final notification)) {
        final display =
            deferredDisplay ??
            NotificationPolicyRegistry.instance.deferredDisplay;
        record = await _orElse(
          () => display.defer(notification, quietHours),
          false,
        );
      }
    }
    if (cap != null && record) {
      await _orElse(() => store.writeDeliveries(tier, [...recent, now]), null);
    }
    return decision;
  }

  static Future<T> _orElse<T>(Future<T> Function() read, T fallback) async {
    try {
      return await read();
    } on Object {
      return fallback;
    }
  }

  static List<DateTime> _inWindow(
    List<DateTime> deliveries,
    DateTime now,
    Duration window,
  ) {
    final since = now.subtract(window);
    return [
      for (final at in deliveries)
        if (at.isAfter(since)) at,
    ];
  }
}
