import 'package:app_config/app_config.dart';
import 'package:dependencies/di.dart';
import 'package:pico/host/push/push_data_update_alerts.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:push_notification_api/push_notification_api.dart';

/// Wires the Pengaturan push port to the generated push contract (S51).
@module
abstract class PushAlertsModule() {
  /// The ADR-0112 flow, hidden when the flavour has no OneSignal App ID.
  @lazySingleton
  DataUpdateAlerts dataUpdateAlerts(PushNotificationSDK sdk) =>
      PushDataUpdateAlerts(sdk: sdk, appId: AppEnv.onesignalAppId);
}
