import 'package:dependencies_core/equality.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:push_notification_api/src/models/push_notification.dart';

/// How much a message may interrupt the user. Senders set it in
/// `data['tier']`.
enum NotificationTier(
  /// Whether the title and body may hold amounts or personal data, so the
  /// lock screen gets generic text instead. Applies only when the sender
  /// sets the tier explicitly (see `PushNotification.sensitive`).
  final bool sensitive,
) {
  /// Security and account alerts. Always shown, never capped.
  critical(true),

  /// Receipts, OTPs, order updates. Also the parsed tier of untagged
  /// messages, which are neither redacted nor capped.
  transactional(true),

  /// Promotions. Needs marketing consent, respects quiet hours and caps.
  marketing(false);

  /// Parses `data['tier']`; unknown or missing values are [transactional].
  static NotificationTier parse(String? raw) => values.firstWhere(
    (tier) => tier.name == raw,
    orElse: () => transactional,
  );
}

/// The user's do-not-disturb window in device-local time, as minutes after
/// midnight, start inclusive and end exclusive.
///
/// `start > end` crosses midnight (22:00-07:00); `start == end` is empty.
/// Both values must be in `0..1439`.
class const QuietHours({
  required final int startMinute,
  required final int endMinute,
}) extends Equatable {
  /// Creates a window.
  this
    : assert(startMinute >= 0 && startMinute < 1440, 'startMinute'),
      assert(endMinute >= 0 && endMinute < 1440, 'endMinute');

  /// Whether [localTime] falls inside the window.
  bool contains(DateTime localTime) {
    final minute = localTime.hour * 60 + localTime.minute;
    if (startMinute <= endMinute) {
      return minute >= startMinute && minute < endMinute;
    }
    return minute >= startMinute || minute < endMinute;
  }

  @override
  List<Object?> get props => [startMinute, endMinute];
}

/// Why a message was not shown.
enum NotificationSuppression() {
  /// Marketing message without `ConsentPurpose.marketing`.
  noConsent,

  /// Marketing message inside the user's quiet hours.
  quietHours,

  /// The tier's frequency cap is used up for the current window.
  capReached,
}

/// The policy's verdict for one incoming message.
sealed class const NotificationDecision();

/// Show [notification]. When its `publicTitle` is set it is sensitive:
/// the vendor posts no OS banner and the app's display uses the public text
/// on the lock screen.
final class const ShowNotification(final PushNotification notification)
    extends NotificationDecision;

/// Do not show the message and do not emit it on the foreground stream.
final class const SuppressNotification(final NotificationSuppression reason)
    extends NotificationDecision;

/// Port that every provider handler calls once per incoming foreground
/// message, before anything is displayed.
abstract interface class NotificationPolicy() {
  /// Decides whether and how [notification] is shown. Each call counts
  /// against the tier's cap when it returns [ShowNotification].
  Future<NotificationDecision> evaluate(PushNotification notification);
}

/// Port that shows a marketing message held back by quiet hours once they
/// end. The default drops it; a display package (such as
/// `local_notification_display`) installs a real one. See ADR-037
/// amendment 2.
abstract interface class DeferredNotificationDisplay() {
  /// Schedules [notification] for the end of [quietHours]. Returns `false`
  /// when it was not scheduled, so the message is dropped.
  Future<bool> defer(PushNotification notification, QuietHours quietHours);
}

/// Holds the installed [NotificationPolicy] and [DeferredNotificationDisplay].
/// Vendor packages read them here so they depend only on this api package.
class NotificationPolicyRegistry._() {
  /// The process-wide registry.
  static final NotificationPolicyRegistry instance =
      NotificationPolicyRegistry._();

  NotificationPolicy _policy = const _ShowAll();
  DeferredNotificationDisplay _deferredDisplay = const _Drop();

  /// The installed policy; shows everything unchanged until [install].
  NotificationPolicy get policy => _policy;

  /// Installs [policy]. `push_notification_impl` calls this before it
  /// resolves any provider handler.
  // Mirrors ConsentGateRegistry.install.
  // ignore: use_setters_to_change_properties
  void install(NotificationPolicy policy) => _policy = policy;

  /// The installed deferred display; drops everything until
  /// [installDeferredDisplay].
  DeferredNotificationDisplay get deferredDisplay => _deferredDisplay;

  /// Installs [display]. Order relative to [install] does not matter: the
  /// policy reads it on each message.
  // ignore: use_setters_to_change_properties
  void installDeferredDisplay(DeferredNotificationDisplay display) =>
      _deferredDisplay = display;

  /// Restores the show-everything policy and the dropping display. Tests only.
  @visibleForTesting
  void reset() {
    _policy = const _ShowAll();
    _deferredDisplay = const _Drop();
  }
}

class const _ShowAll() implements NotificationPolicy {
  @override
  Future<NotificationDecision> evaluate(PushNotification notification) async =>
      ShowNotification(notification);
}

class const _Drop() implements DeferredNotificationDisplay {
  @override
  Future<bool> defer(
    PushNotification notification,
    QuietHours quietHours,
  ) async => false;
}
