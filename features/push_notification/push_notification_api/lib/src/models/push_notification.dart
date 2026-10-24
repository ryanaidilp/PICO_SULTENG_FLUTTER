import 'package:dependencies_core/equality.dart';
import 'package:push_notification_api/src/policy/notification_policy.dart';
import 'package:push_notification_api/src/push_notification_sdk.dart';

/// An incoming push notification payload.
class const PushNotification({
  /// Provider-assigned message identifier.
  required final String id,

  /// UTC timestamp when the notification was received / tapped.
  required final DateTime receivedAt,

  /// Optional notification title.
  final String? title,

  /// Optional notification body.
  final String? body,

  /// Optional deep-link route carried in the notification data.
  ///
  /// Populated from `data['route']` when present. The host app subscribes
  /// to [PushNotificationSDK.tapStream] and reads this field to drive
  /// navigation (e.g. `context.router.push(RouteUri.parse(notification.route))`).
  final String? route,

  /// Arbitrary key-value data from the notification payload.
  final Map<String, String> data = const {},

  /// Lock-screen-safe title (Android `publicVersion`). `null` means [title]
  /// is safe to show on the lock screen. Set by [NotificationPolicy].
  final String? publicTitle,

  /// Lock-screen-safe body. `null` means [body] is safe to show.
  final String? publicBody,
}) extends Equatable {
  /// Creates a [PushNotification].
  this;

  /// The sender's tier from `data['tier']`.
  NotificationTier get tier => NotificationTier.parse(data['tier']);

  /// Whether the sender set a known `data['tier']`. Untagged messages keep
  /// the pre-policy behaviour: no redaction, no cap.
  bool get tagged => data['tier'] == tier.name;

  /// Whether the lock screen needs generic text. Opt-in only:
  /// `data['sensitive'] == 'true'` or an explicit sensitive tier.
  bool get sensitive =>
      data['sensitive'] == 'true' || (tagged && tier.sensitive);

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    route,
    data,
    receivedAt,
    publicTitle,
    publicBody,
  ];
}
