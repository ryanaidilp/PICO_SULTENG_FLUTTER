import 'package:core/src/di/service_locator.config.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/home.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: false,
  asExtension: false,
  externalPackageModulesAfter: [
    ExternalModule(HomePackageModule),
  ],
)
Future<void> configureDependencies() async => $initGetIt(getIt);
