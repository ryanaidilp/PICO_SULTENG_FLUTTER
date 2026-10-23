/// Generates the DI injector.dart file.
String injectorTemplate({required String appName}) =>
    '''
import 'package:app_utilities/app_utilities.dart';
import 'package:auth_impl/auth_impl.dart';
import 'package:dependencies/di.dart';
import 'package:home_impl/home_impl.dart';
import 'package:introduction/introduction.dart';
import 'package:monitoring_impl/monitoring_impl.dart';
import 'package:network_sdk_dio/network_sdk_dio.dart';
import 'package:paywall_impl/paywall_impl.dart';
import 'package:router_registry/router_registry.dart';
import 'package:$appName/di/injector.config.dart';
import 'package:websocket_sdk_dart/websocket_sdk_dart.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'\$initGetIt',
  asExtension: false,
  externalPackageModulesBefore: [
    ExternalModule(AppUtilitiesPackageModule),
    ExternalModule(NetworkSdkDioPackageModule),
    ExternalModule(WebsocketSdkDartPackageModule),
    ExternalModule(MonitoringImplPackageModule),
    ExternalModule(RouterRegistryPackageModule),
    // Auth registers its SDK eagerly: it restores the session before the
    // first frame.
    ExternalModule(AuthImplGlobalModule),
    // The rest register a manifest and a lazy SDK; their order does not
    // matter.
    ExternalModule(IntroductionGlobalModule),
    ExternalModule(HomeImplGlobalModule),
    ExternalModule(PaywallImplGlobalModule),
  ],
)
Future<void> initializeInjector() => \$initGetIt(getIt);
''';
