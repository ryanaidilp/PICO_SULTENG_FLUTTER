import 'package:app_utilities/app_utilities.dart';
import 'package:dependencies/di.dart';
import 'package:router_registry/router_registry.dart';
import 'package:pico/di/injector.config.dart';

// archipelago:feature_imports:start
import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:monitoring_impl/monitoring_impl.dart';
import 'package:network_sdk_dio/network_sdk_dio.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

// archipelago:feature_imports:end

final getIt = GetIt.instance;
@InjectableInit(
  initializerName: r'$initGetIt',
  asExtension: false,
  externalPackageModulesBefore: [
    ExternalModule(AppUtilitiesPackageModule),
    ExternalModule(RouterRegistryPackageModule),
    // archipelago:feature_modules_before:start
    ExternalModule(AppLaunchTrackerImplPackageModule),
    ExternalModule(MonitoringImplPackageModule),
    ExternalModule(NetworkSdkDioPackageModule),
    ExternalModule(PicoDataImplPackageModule),
    // archipelago:feature_modules_before:end
  ],
  externalPackageModulesAfter: [
    // archipelago:feature_modules_after:start
    // archipelago:feature_modules_after:end
  ],
)
Future<void> initializeInjector() => $initGetIt(getIt);
