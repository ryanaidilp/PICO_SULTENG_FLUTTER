import 'package:app_config/app_config.dart';

import 'package:consent_api/consent_api.dart';
import 'package:dependencies/di.dart';
import 'package:push_notification_onesignal_impl/src/onesignal_config.dart';

/// Provides the [OneSignalConfig] the handler initializes OneSignal with.
///
/// The App ID comes from `ONESIGNAL_APP_ID` in the flavor's `.env.<flavor>`,
/// so each flavor can use its own OneSignal app.
@module
abstract class OneSignalRegisterModule() {
  /// The OneSignal App ID and consent purpose for this build.
  @lazySingleton
  OneSignalConfig get oneSignalConfig => OneSignalConfig(
    appId: AppEnv.onesignalAppId,
    consentPurpose: ConsentPurpose.marketing,
  );
}
