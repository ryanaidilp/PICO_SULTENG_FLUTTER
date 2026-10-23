import 'package:dependencies/di.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Initialize core infrastructure dependencies.
/// This should be called early in the application lifecycle.
@microPackageInit
Future<void> setupCoreInfrastructureDependencies() async {}
