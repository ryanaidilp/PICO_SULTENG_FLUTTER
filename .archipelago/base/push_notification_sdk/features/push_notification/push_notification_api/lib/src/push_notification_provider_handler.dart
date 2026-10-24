import 'package:push_notification_api/src/models/push_notification.dart';
import 'package:push_notification_api/src/models/push_notification_permission.dart';
import 'package:push_notification_api/src/models/push_notification_provider.dart';
import 'package:push_notification_api/src/models/push_token.dart';

/// Contract that each push notification provider package implements.
///
/// Provider packages register a concrete handler with GetIt so the
/// push notification SDK orchestrator can discover them at runtime via
/// `getIt.getAll<PushNotificationProviderHandler>()`.
///
/// Register under a unique `@Named(...)` key (e.g. `@Named('fcm')`):
/// GetIt rejects a second unnamed registration of the same type, and
/// `getAll` returns named registrations too.
abstract interface class PushNotificationProviderHandler() {
  /// The provider this handler supports.
  PushNotificationProvider get provider;

  /// Request notification permission.
  ///
  /// On iOS this shows the system prompt; on Android 13+ it triggers the
  /// runtime permission dialog. Returns the post-prompt state.
  Future<PushNotificationPermission> requestPermission();

  /// Return the current permission state without prompting.
  Future<PushNotificationPermission> getPermissionStatus();

  /// Return the current device token, or `null` if unavailable.
  Future<PushToken?> getToken();

  /// Subscribe to a topic segment (e.g. `"premium-users"`). Idempotent.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic segment. Idempotent.
  Future<void> unsubscribeFromTopic(String topic);

  /// Stream of notifications received while the app is in the foreground.
  ///
  /// Each incoming message goes through
  /// `NotificationPolicyRegistry.instance.policy.evaluate` exactly once,
  /// before any OS banner. Suppressed messages are not emitted; a message
  /// with `publicTitle` set gets no OS banner.
  Stream<PushNotification> get foregroundStream;

  /// Stream of notification-tap events (background tap or terminated-launch).
  ///
  /// Each event carries the full [PushNotification] payload including
  /// [PushNotification.route] for tap-driven navigation.
  Stream<PushNotification> get tapStream;

  /// Clear local state (called on logout).
  ///
  /// Unregisters the device token at the provider and clears any active
  /// topic subscriptions.
  Future<void> clearAll();
}
