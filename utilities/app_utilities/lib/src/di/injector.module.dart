// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:app_utilities/src/di/third_party_module.dart' as _i873;
import 'package:app_utilities/src/log/log.dart' as _i211;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;

class AppUtilitiesPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final thirdPartyModule = _$ThirdPartyModule();
    gh.factory<_i974.Logger>(() => thirdPartyModule.logger);
    gh.lazySingleton<_i211.Log>(() => _i211.Log(gh<_i974.Logger>()));
  }
}

class _$ThirdPartyModule extends _i873.ThirdPartyModule {}
