import 'dart:async';

import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/src/policy/default_notification_policy.dart';
import 'package:push_notification_impl/src/push_notification_sdk_impl.dart';

/// Manual global module for push_notification_impl.
///
/// Must be registered AFTER all provider packages
/// (e.g. `push_notification_fcm_impl`)
/// because [PushNotificationSDKImpl.create] resolves
/// `getIt.getAll<PushNotificationProviderHandler>()` at construction time.
///
/// Usage in the main app:
/// ```dart
/// @InjectableInit(
///   externalPackageModulesBefore: [
///     // Provider package(s) first — handler must be in GetIt before the
///     // orchestrator calls getAll<PushNotificationProviderHandler>().
///     ExternalModule(PushNotificationFcmImplPackageModule),
///     // Orchestrator last.
///     ExternalModule(PushNotificationGlobalModule),
///   ],
/// )
/// ```
class PushNotificationGlobalModule() extends MicroPackageModule {
  @override
  FutureOr<void> init(GetItHelper gh) {
    // Before the handlers are built, so their first message is evaluated.
    NotificationPolicyRegistry.instance.install(DefaultNotificationPolicy());
    // Eager on purpose: building the handlers attaches the vendor message and
    // tap listeners (and starts OneSignal) at boot, before the first push.
    GetIt.instance.registerSingleton<PushNotificationSDK>(
      PushNotificationSDKImpl.create(handlers: _resolveHandlers()),
    );
  }

  /// All installed handlers, minus any that fail to construct.
  ///
  /// A handler that throws while being built (FCM before
  /// `flutterfire configure`, so `Firebase.initializeApp()` failed) must not
  /// block boot: this runs inside `initializeInjector()`. The fast path is
  /// `getAll`; on failure each known provider key is resolved on its own.
  static List<PushNotificationProviderHandler> _resolveHandlers() {
    final getIt = GetIt.instance;
    try {
      return getIt.getAll<PushNotificationProviderHandler>().toList();
    } catch (error) {
      // Handlers registered under a name outside PushNotificationProvider are
      // not recovered below; say so instead of dropping them silently.
      debugPrint(
        '[push] getAll failed, resolving known providers only: $error',
      );
      final handlers = <PushNotificationProviderHandler>[];
      for (final provider in PushNotificationProvider.values) {
        final name = provider.name;
        if (!getIt.isRegistered<PushNotificationProviderHandler>(
          instanceName: name,
        )) {
          continue;
        }
        try {
          handlers.add(
            getIt<PushNotificationProviderHandler>(instanceName: name),
          );
        } catch (error) {
          debugPrint('[push] provider "$name" disabled: $error');
        }
      }
      return handlers;
    }
  }
}
