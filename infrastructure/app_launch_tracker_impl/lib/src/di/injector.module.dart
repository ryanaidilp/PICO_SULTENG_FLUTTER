// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:app_launch_tracker_impl/src/app_launch_tracker_impl.dart'
    as _i389;
import 'package:injectable/injectable.dart' as _i526;

class AppLaunchTrackerImplPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i389.AppLaunchTracker>(() => _i389.AppLaunchTracker());
  }
}
