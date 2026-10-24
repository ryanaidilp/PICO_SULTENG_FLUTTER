import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:push_notification_api/push_notification_api.dart';

/// The topic every "Kabar pembaruan data" subscriber joins. The OneSignal
/// handler stores it as the tag `topic_data_update` (ADR-0112).
const String kDataUpdateTopic = 'data_update';

/// The ADR-0112 opt-in flow on top of the generated [PushNotificationSDK].
///
/// Nothing here touches the push vendor until [enable] runs, and [enable] runs
/// only after the user accepted the explain sheet. Consent goes through the
/// contract's `setMarketingEnabled`, which records the consent purpose that
/// gates OneSignal in the generated config (`ConsentPurpose.marketing`; see
/// the Archipelago question about a dedicated notifications purpose).
class PushDataUpdateAlerts implements DataUpdateAlerts {
  /// Creates the flow. `appId` is `AppEnv.onesignalAppId`; `openSettings`
  /// opens the OS page of this app (replaced in tests).
  PushDataUpdateAlerts({
    required this._sdk,
    required this._appId,
    Future<void> Function()? openSettings,
  }) : _openSettings = openSettings ?? _openAppNotificationSettings;

  final PushNotificationSDK _sdk;
  final String _appId;
  final Future<void> Function() _openSettings;

  static Future<void> _openAppNotificationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  @override
  bool get available =>
      _appId.trim().isNotEmpty &&
      _sdk.availableProviders.contains(PushNotificationProvider.oneSignal);

  @override
  Future<bool> osPermissionGranted() async =>
      await _sdk.getPermissionStatus() == PushNotificationPermission.granted;

  @override
  Future<DataUpdateAlertsOutcome> enable() async {
    if (!available) return DataUpdateAlertsOutcome.failed;
    try {
      // Step 4a: consent first, so OneSignal may start. It stays dormant
      // until this call.
      await _sdk.setMarketingEnabled(enabled: true);
      // Step 4b: the OS dialog (Android 13+ and iOS).
      final permission = await _sdk.requestPermission();
      if (permission != PushNotificationPermission.granted) {
        // Step 5: denied. Take the consent back so OneSignal goes dormant.
        await _sdk.setMarketingEnabled(enabled: false);
        return DataUpdateAlertsOutcome.denied;
      }
      // Step 4c: the topic tag.
      await _sdk.subscribeToTopic(kDataUpdateTopic);
      return DataUpdateAlertsOutcome.enabled;
    } on Object catch (error, stack) {
      debugPrint('[push] enable failed: $error\n$stack');
      await _revokeQuietly();
      return DataUpdateAlertsOutcome.failed;
    }
  }

  @override
  Future<void> disable() async {
    // Step 6: unsubscribe, opt out, revoke consent. Each step runs even when
    // an earlier one fails, so the user is never left half subscribed.
    var failed = false;
    try {
      await _sdk.unsubscribeFromTopic(kDataUpdateTopic);
    } on Object catch (error) {
      debugPrint('[push] unsubscribe failed: $error');
      failed = true;
    }
    try {
      await _sdk.clearAll();
    } on Object catch (error) {
      debugPrint('[push] opt out failed: $error');
      failed = true;
    }
    await _revokeQuietly();
    if (failed) throw StateError('push opt-out was incomplete');
  }

  @override
  Future<void> openSystemSettings() => _openSettings();

  Future<void> _revokeQuietly() async {
    try {
      await _sdk.setMarketingEnabled(enabled: false);
    } on Object catch (error) {
      debugPrint('[push] revoke failed: $error');
    }
  }
}
