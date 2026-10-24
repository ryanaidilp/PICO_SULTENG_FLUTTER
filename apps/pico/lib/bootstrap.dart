import 'dart:async';

import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
import 'package:app_marionette/app_marionette.dart';
import 'package:app_utilities/app_utilities.dart';
import 'package:consent_impl/consent_impl.dart';
import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locale_core/locale_core.dart';
import 'package:monitoring_api/monitoring_api.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/host/host_app_widget.dart';
import 'package:pico/host/initializers/initializer.dart';
import 'package:pico/host/initializers/pre_launch_initializer.dart';
import 'package:pico/host/push/push_tap_router.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:push_notification_api/push_notification_api.dart';

/// Builder function that receives the initialization result.
typedef AppBuilder = Widget Function(InitializerResult result);

/// Loading indicator shown by [HostAppWidget] while pre-launch
/// initialization runs — before `MaterialApp`'s `theme`/`darkTheme` (and
/// therefore any ambient `Theme`) is mounted, so this can't use
/// `context.colors`/`Theme.of(context)` like the rest of the app. It reads
/// brand colors directly from [PicoColorToken]/
/// [PicoColorFoundation] instead, and picks the
/// light/dark variant via [MediaQuery.platformBrightnessOf], which only
/// depends on OS-level brightness and is available this early — this keeps
/// the loading screen from flashing Flutter's default purple `ColorScheme`
/// between the native splash screen and the app's real theme.
class const _BootstrapLoadingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return ColoredBox(
      color: isDark
          ? PicoColorFoundation.bgMainDark
          : PicoColorFoundation.bgMain,
      child: Center(
        child: CircularProgressIndicator(
          color: isDark ? PicoColorToken.primary400 : PicoColorToken.primary600,
        ),
      ),
    );
  }
}

/// Installs the app's `FlutterError.onError` and
/// `PlatformDispatcher.instance.onError` handlers.
///
/// These are the only global handlers: monitoring vendors are reached
/// through the consent-gated `AppMonitoring` binding and never install their
/// own (Archipelago-kvvi).
void installGlobalErrorHandlers() {
  // Layer 2: Flutter framework errors.
  FlutterError.onError = (details) {
    final exceptionStr = details.exception.toString();
    final isLocalizationError =
        exceptionStr.contains('CupertinoLocalizations') ||
        exceptionStr.contains('localization delegates');
    if (isLocalizationError) return;

    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    safeReportFatalCrash(details.exception, details.stack ?? StackTrace.empty);
    if (GetIt.I.isRegistered<AppMonitoring>()) {
      unawaited(GetIt.I<AppMonitoring>().recordFlutterError(details));
    }
  };

  // Layer 3: Platform dispatcher errors (isolate + platform channel errors).
  PlatformDispatcher.instance.onError = (error, stack) {
    safeReportFatalCrash(error, stack);
    if (GetIt.I.isRegistered<AppMonitoring>()) {
      GetIt.I<AppMonitoring>().recordError(error, stack, fatal: true);
    }
    return true;
  };
}

/// Starts the monitoring vendors when monitoring is installed.
///
/// Must run after `ConsentInitializer`: `ConsentAwareMonitoring` defers vendor
/// start-up until diagnostics consent is granted.
Future<void> initializeMonitoring() async {
  if (GetIt.I.isRegistered<AppMonitoring>()) {
    await GetIt.I<AppMonitoring>().initialize();
  }
}

Future<void> bootstrap({
  required String flavor,
  required AppBuilder builder,
}) async => runZonedGuarded(
  () async {
    // First statement of every flavor's main(): the launch trace's
    // `dart_main` marker.
    markDartMain();

    // The only binding in the process: MarionetteBinding in debug builds (an
    // AI agent can drive the app over MCP), the plain binding otherwise.
    // Release and profile builds swap in app_marionette_noop (build-prepare
    // --mode). Nothing above may touch the binding.
    ensureAppBinding(isInteractiveElement: isUiKitInteractive);
    // archipelago:app_debugger:pre_init:start
    // archipelago:app_debugger:pre_init:end

    // Layers 2 and 3 — set up before DI so errors during init are also
    // captured.
    installGlobalErrorHandlers();

    // Consent must be installed before anything can resolve AppMonitoring or
    // AnalyticTracker. It is a blocking pre-launch step for that reason: a
    // gate installed after the first tracked event does not gate that event.
    //
    // The gate fails closed — every purpose is denied until the app records a
    // decision via getIt<ConsentGate>().record(...) from your consent sheet.
    // For QA and integration runs, launch with
    // `--dart-define=CONSENT_DEBUG_GRANT_ALL=true` (debug builds only); see
    // ConsentDebugOverride.
    await ConsentInitializer.initialize(GetIt.I);

    // Firebase-backed vendors (Crashlytics, FCM, Firebase Analytics, Remote
    // Config) read Firebase singletons while DI builds them, so the default
    // app must exist before initializeInjector(). Their bricks fill this
    // region with a guarded Firebase.initializeApp(); until
    // `flutterfire configure` runs it fails and those vendors are skipped.
    // archipelago:firebase:init:start
    // archipelago:firebase:init:end

    // Restore the user's saved language before the first frame.
    //
    // slang's LocaleSettings is in-memory only, so without this every cold
    // start silently reverts to the base locale. Restoring here — before
    // initializeInjector() and runApp() — means every feature shell seeds its
    // own scoped slang instance from the correct app-wide locale on its first
    // build, so there is no flash of the base locale.
    //
    // Never throws: a storage failure degrades to "no saved preference".
    await AppLocaleController.restore();

    await initializeInjector();

    // Subscribe to notification taps before the first frame: the tap that
    // cold-started the app can arrive before the router exists. The router
    // attaches in PicoApp (S51, ADR-0112 step 7).
    if (getIt.isRegistered<PushNotificationSDK>()) {
      getIt.registerSingleton<PushTapRouter>(
        PushTapRouter(getIt<PushNotificationSDK>().tapStream),
      );
    }

    // Non-blocking: crash reporting must not delay the first frame.
    unawaited(initializeMonitoring());

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // archipelago:app_debugger:pre_run:start
    // archipelago:app_debugger:pre_run:end
    runApp(
      HostAppWidget(
        initializerController: PreLaunchInitializerController.create(),
        builder: (context, result) => builder(result),
        loadingWidget: const _BootstrapLoadingIndicator(),
      ),
    );
  },
  // Layer 1: Uncaught async errors from runZonedGuarded.
  (error, stackTrace) {
    safeReportFatalCrash(error, stackTrace);
    if (GetIt.I.isRegistered<AppMonitoring>()) {
      GetIt.I<AppMonitoring>().recordError(error, stackTrace, fatal: true);
    }
  },
);
