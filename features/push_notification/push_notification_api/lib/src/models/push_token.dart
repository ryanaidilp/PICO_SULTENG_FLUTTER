import 'package:dependencies_core/equality.dart';
import 'package:push_notification_api/src/models/push_notification_provider.dart';

/// A device registration token from a push notification provider.
class const PushToken({
  /// The provider that issued this token.
  required final PushNotificationProvider provider,

  /// Raw token string (FCM registration token or OneSignal subscription ID).
  required final String token,

  /// UTC timestamp when the token was last refreshed.
  required final DateTime updatedAt,
}) extends Equatable {
  /// Creates a [PushToken].
  this;

  @override
  List<Object?> get props => [provider, token, updatedAt];
}
