// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:monitoring_api/monitoring_api.dart' as _i321;
import 'package:monitoring_impl/src/consent_aware_monitoring.dart' as _i563;
import 'package:monitoring_impl/src/di/register_module.dart' as _i465;
import 'package:monitoring_impl/src/monitoring_fanout_impl.dart' as _i166;

class MonitoringImplPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final monitoringRegisterModule = _$MonitoringRegisterModule();
    gh.lazySingleton<List<_i321.AppMonitoringVendor>>(
      () => monitoringRegisterModule.monitoringVendors,
    );
    gh.lazySingleton<_i166.MonitoringFanoutImpl>(
      () => _i166.MonitoringFanoutImpl(gh<List<_i321.AppMonitoringVendor>>()),
    );
    gh.lazySingleton<_i321.AppMonitoring>(
      () =>
          _i563.ConsentAwareMonitoring.fromDi(gh<_i166.MonitoringFanoutImpl>()),
    );
  }
}

class _$MonitoringRegisterModule extends _i465.MonitoringRegisterModule {}
