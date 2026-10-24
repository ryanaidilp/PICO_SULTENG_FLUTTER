import 'package:feature_sdk/feature_sdk.dart';
import 'package:push_notification_api/src/models/notification_preferences.dart';
import 'package:push_notification_api/src/models/push_notification.dart';
import 'package:push_notification_api/src/models/push_notification_permission.dart';
import 'package:push_notification_api/src/models/push_notification_provider.dart';
import 'package:push_notification_api/src/models/push_token.dart';
import 'package:push_notification_api/src/policy/notification_policy.dart';
import 'package:push_notification_api/src/push_notification_provider_handler.dart';

/// Consumer-facing contract for push notifications.
///
/// Obtain via `getIt<PushNotificationSDK>()`. A single provider handler
/// (FCM _or_ OneSignal — the brick generates whichever the user picks)
/// registers a [PushNotificationProviderHandler] implementation which this
/// SDK discovers and delegates to at runtime.
///
/// Example:
/// ```dart
/// final pushSDK = getIt<PushNotificationSDK>();
///
/// // Request permission on first launch.
/// final permission = await pushSDK.requestPermission();
///
/// // Subscribe to tap events for navigation.
/// pushSDK.tapStream.listen((notification) {
///   if (notification.route != null) {
///     context.router.push(RouteUri.parse(notification.route!));
///   }
/// });
/// ```
///
/// [launch] opens the notification settings page (quiet hours and
/// marketing), also reachable at [settingsPath].
abstract interface class PushNotificationSDK() implements FeatureSDK {
  /// Route of the notification settings page. Other features (home's
  /// settings) navigate to it by path, without depending on this package.
  static const String settingsPath = '/notification-settings';

  /// Providers with a registered handler at runtime.
  ///
  /// Typically contains a single provider (FCM OR OneSignal) — whichever
  /// package was wired into the app's DI graph.
  Set<PushNotificationProvider> get availableProviders;

  /// Request notification permission (iOS prompt, Android 13+ runtime dialog).
  ///
  /// Returns the post-prompt state. Safe to call multiple times — the OS only
  /// shows the system dialog once.
  Future<PushNotificationPermission> requestPermission();

  /// Return the current permission state without prompting.
  Future<PushNotificationPermission> getPermissionStatus();

  /// Return the current device token from the active provider.
  ///
  /// Returns `null` when permission is denied or the token is not yet ready.
  Future<PushToken?> getToken();

  /// Subscribe to a topic segment (e.g. `"premium-users"`). Idempotent.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic segment. Idempotent.
  Future<void> unsubscribeFromTopic(String topic);

  /// Stream of notifications received while the app is in the foreground.
  ///
  /// Only messages the [NotificationPolicy] shows are emitted. When
  /// [PushNotification.publicTitle] is set, the vendor posted no OS banner:
  /// display it yourself and use the public text on the lock screen.
  Stream<PushNotification> get foregroundStream;

  /// The user's quiet hours, or `null` when none are set.
  Future<QuietHours?> getQuietHours();

  /// Sets the user's quiet hours; `null` clears them. Marketing messages
  /// inside the window are dropped.
  Future<void> setQuietHours(QuietHours? quietHours);

  /// Whether marketing messages may be shown. Reads the user's
  /// `ConsentPurpose.marketing` decision, which the policy checks.
  bool get marketingEnabled;

  /// Records the user's marketing decision (`ConsentPurpose.marketing`).
  /// Critical and transactional messages are not affected.
  Future<void> setMarketingEnabled({required bool enabled});

  /// The time zone, quiet hours and marketing consent for your backend's
  /// notification policy (ADR-041). Send `toJson()` with the push token,
  /// and again when the user changes a setting.
  Future<NotificationPreferences> notificationPreferences();

  /// Stream of notification-tap events (background tap or terminated-launch).
  ///
  /// Each event carries the full [PushNotification] payload. Read
  /// [PushNotification.route] to drive navigation in the host app.
  Stream<PushNotification> get tapStream;

  /// Clear local state (typically called on logout).
  ///
  /// Unregisters the device token at the provider and clears subscriptions.
  Future<void> clearAll();
}
