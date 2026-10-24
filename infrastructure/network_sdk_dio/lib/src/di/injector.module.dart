// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:dio/dio.dart' as _i361;
import 'package:injectable/injectable.dart' as _i526;
import 'package:network_sdk_dio/network_sdk_dio.dart' as _i754;
import 'package:network_sdk_dio/src/di/register_module.dart' as _i788;

class NetworkSdkDioPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i361.Dio>(() => registerModule.httpClient());
    gh.lazySingleton<_i754.HttpClient>(
      () => registerModule.apiHttpClient(gh<_i361.Dio>()),
    );
  }
}

class _$RegisterModule extends _i788.RegisterModule {}
