/// Push notification SDK orchestrator.
///
/// Aggregates provider handlers (FCM or OneSignal) and exposes a unified
/// [PushNotificationSDK] interface.
library;

import 'package:push_notification_api/push_notification_api.dart';

export 'src/di/push_notification_global_module.dart'
    show PushNotificationGlobalModule;
export 'src/policy/default_notification_policy.dart';
export 'src/policy/notification_policy_store.dart';
export 'src/push_notification_sdk_impl.dart';
