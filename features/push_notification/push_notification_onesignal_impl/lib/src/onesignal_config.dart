import 'package:consent_api/consent_api.dart';

/// What `OneSignalPushNotificationHandler` needs from the host app.
///
/// Provided by `OneSignalRegisterModule`, which reads the App ID from the
/// active flavor's env (`ONESIGNAL_APP_ID`). Tests build their own.
class const OneSignalConfig({
  /// The OneSignal App ID, from Settings > Keys & IDs in the OneSignal
  /// dashboard. Not a secret.
  required final String appId,

  /// The consent purpose that gates the OneSignal SDK, or `null` to start it
  /// without a consent gate (the OS notification permission is then the only
  /// opt-in).
  required final ConsentPurpose? consentPurpose,
}) {
  /// Creates a [OneSignalConfig].
  this;
}
