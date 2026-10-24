// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:push_notification_api/push_notification_api.dart' as _i257;
import 'package:push_notification_onesignal_impl/src/di/register_module.dart'
    as _i491;
import 'package:push_notification_onesignal_impl/src/onesignal_config.dart'
    as _i803;
import 'package:push_notification_onesignal_impl/src/onesignal_push_notification_handler.dart'
    as _i205;

class PushNotificationOnesignalImplPackageModule
    extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final oneSignalRegisterModule = _$OneSignalRegisterModule();
    gh.lazySingleton<_i803.OneSignalConfig>(
      () => oneSignalRegisterModule.oneSignalConfig,
    );
    gh.lazySingleton<_i257.PushNotificationProviderHandler>(
      () => _i205.OneSignalPushNotificationHandler(gh<_i803.OneSignalConfig>()),
      instanceName: 'oneSignal',
    );
  }
}

class _$OneSignalRegisterModule extends _i491.OneSignalRegisterModule {}
