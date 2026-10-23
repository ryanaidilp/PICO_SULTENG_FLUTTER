/// Generates the bootstrap.dart file.
String bootstrapTemplate({required String appName}) =>
    '''
import 'dart:async';

import 'package:app_config/app_config.dart';
import 'package:consent_impl/consent_impl.dart';
import 'package:dependencies/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:$appName/benchmark.dart';
import 'package:$appName/di/injector.dart';
import 'package:$appName/host/host_app_widget.dart';
import 'package:$appName/host/initializers/initializer.dart';
import 'package:$appName/host/initializers/pre_launch_initializer.dart';

/// Builder function that receives the initialization result.
typedef AppBuilder =
    Widget Function(InitializerResult result, StartupBenchmark benchmark);

Future<void> bootstrap({
  required FlavorStatus flavor,
  required AppBuilder builder,
}) async => runZonedGuarded(
  () async {
    Flavor.status = flavor;

    WidgetsFlutterBinding.ensureInitialized();

    // Consent must be installed before anything can resolve AppMonitoring or
    // AnalyticTracker: a gate installed after the first tracked event does not
    // gate that event. The gate fails closed until the app records a decision.
    await ConsentInitializer.initialize(GetIt.I);

    await initializeInjector();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final benchmark = StartupBenchmark(mode: flavor.name)..startApp();

    runApp(
      HostAppWidget(
        benchmark: benchmark,
        initializerController: PreLaunchInitializerController.create(),
        builder: (context, result) => builder(result, benchmark),
      ),
    );
  },
  (error, stackTrace) {
    debugPrint('Uncaught error: \$error');
    debugPrint('Stack trace: \$stackTrace');
  },
);
''';
