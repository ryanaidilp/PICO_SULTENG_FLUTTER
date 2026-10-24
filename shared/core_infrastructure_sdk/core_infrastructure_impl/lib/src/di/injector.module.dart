// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core_infrastructure_api/core_infrastructure_api.dart' as _i636;
import 'package:core_infrastructure_impl/src/di/register_module.dart' as _i108;
import 'package:core_infrastructure_impl/src/log/log.dart' as _i282;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;

class CoreInfrastructureImplPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i974.Logger>(() => registerModule.logger);
    gh.lazySingleton<_i636.Log>(
      () => _i282.LogImpl(logger: gh<_i974.Logger>()),
    );
  }
}

class _$RegisterModule extends _i108.RegisterModule {}
