import 'package:dependencies/di.dart';

export 'injector.module.dart' show AppLaunchTrackerImplPackageModule;

/// Configures dependency injection for app_launch_tracker_impl package.
@InjectableInit.microPackage()
void initAppLaunchTrackerModule() {}
