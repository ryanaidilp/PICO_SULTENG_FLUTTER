import 'package:dependencies/di.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring_api/monitoring_api.dart';

/// Fanout orchestrator — dispatches every [AppMonitoring] call to all
/// registered, enabled [AppMonitoringVendor]s.
///
/// [_vendors] is supplied by `MonitoringRegisterModule.monitoringVendors`,
/// which collects the `AppMonitoringVendor` registered under each known
/// `@Named(...)` key — i.e. exactly the vendor bricks this project has
/// installed. A vendor brick that was never added never registers, so it is
/// silently excluded from the list; this class does not special-case
/// "missing" vendors itself and works correctly with zero, one, or all four
/// present.
///
/// Example DI wiring in `apps/template_app/lib/di/injector.dart`:
/// ```dart
/// @InjectableInit(
///   externalPackageModulesBefore: [
///     ExternalModule(MonitoringImplPackageModule),
///     ExternalModule(SentryMonitoringImplPackageModule),  // optional
///   ],
/// )
/// ```
///
/// Registered under its own type, **not** as `AppMonitoring`:
/// `ConsentAwareMonitoring` holds that binding and wraps this class, so
/// `getIt<AppMonitoring>()` always returns the consent-gated, scrubbed
/// instance. Resolving `MonitoringFanoutImpl` directly bypasses both checks
/// and should not appear in application code.
@lazySingleton
class MonitoringFanoutImpl(final List<AppMonitoringVendor> _vendors)
    implements AppMonitoring, ConsentWithdrawalAware {
  @override
  bool get isEnabled => _vendors.any((v) => v.isEnabled);

  @override
  Future<void> initialize() async {
    // Call initialize() on ALL vendors regardless of their current enabled
    // state — initialize() is what transitions them from disabled → enabled.
    // Global error handlers belong to bootstrap.dart, which reaches vendors
    // through recordFlutterError; installing them here would replace its
    // filtering and bypass the consent gate (Archipelago-kvvi).
    await _fanoutAll((v) => v.initialize());
  }

  @override
  Future<void> dispose() async {
    // Call dispose() on ALL currently-enabled vendors.
    await _fanoutAsync((v) => v.dispose());
  }

  /// Tells every enabled vendor to stop collecting and drop what it buffered.
  ///
  /// Vendors without [ConsentWithdrawalAware] fall back to [dispose].
  @override
  Future<void> onConsentWithdrawn() => _fanoutAsync(
    (v) => v is ConsentWithdrawalAware
        ? (v as ConsentWithdrawalAware).onConsentWithdrawn()
        : v.dispose(),
  );

  @override
  Future<void> setUserContext(
    String userId, {
    Map<String, dynamic>? extras,
  }) async {
    await _fanoutAsync((v) => v.setUserContext(userId, extras: extras));
  }

  @override
  Future<void> clearUserContext() async {
    await _fanoutAsync((v) => v.clearUserContext());
  }

  @override
  void log(
    String message, {
    String? tag,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {
    _fanoutSync((v) => v.log(message, tag: tag, level: level));
  }

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    await _fanoutAsync(
      (v) =>
          v.recordError(exception, stackTrace, fatal: fatal, context: context),
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _fanoutAsync(
      (v) => v is FlutterAwareMonitoringVendor
          ? (v as FlutterAwareMonitoringVendor).recordFlutterError(details)
          : v.recordError(
              details.exception,
              details.stack,
              fatal: true,
              context: {'source': 'FlutterError'},
            ),
    );
  }

  @override
  Future<T> recordTransaction<T>(
    String name,
    Future<T> Function() action, {
    String? operation,
    Map<String, dynamic>? data,
  }) async {
    if (!isEnabled) return await action();

    T? result;
    Object? error;
    StackTrace? errorStack;

    final stopwatch = Stopwatch()..start();
    try {
      result = await action();
    } catch (e, stack) {
      error = e;
      errorStack = stack;
    } finally {
      stopwatch.stop();
    }

    await _fanoutAsync(
      (v) => v.recordTransaction<void>(
        name,
        () async {
          if (error != null) Error.throwWithStackTrace(error, errorStack!);
        },
        operation: operation,
        data: {
          // A caller-supplied duration (launch phase spans) wins; the replay
          // above only times an empty action.
          'duration_ms': stopwatch.elapsedMilliseconds,
          ...?data,
          // Type only: the message would reach vendors after the consent
          // decorator scrubbed `data`.
          if (error != null) 'error': error.runtimeType.toString(),
        },
      ),
    );

    if (error != null) Error.throwWithStackTrace(error, errorStack!);
    return result as T;
  }

  @override
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    MonitoringLevel level = MonitoringLevel.debug,
  }) {
    _fanoutSync(
      (v) =>
          v.breadcrumb(message, category: category, data: data, level: level),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fans out [action] to ALL vendors, regardless of their [isEnabled] state.
  ///
  /// Used by lifecycle methods such as [initialize] where the vendor's own
  /// [initialize] call is what transitions it from disabled → enabled.
  Future<void> _fanoutAll(
    Future<void> Function(AppMonitoringVendor v) action,
  ) async {
    for (final vendor in _vendors) {
      try {
        await action(vendor);
      } catch (e, stack) {
        debugPrint('[monitoring] ${vendor.vendorName} threw: $e\n$stack');
      }
    }
  }

  Future<void> _fanoutAsync(
    Future<void> Function(AppMonitoringVendor v) action,
  ) async {
    for (final vendor in _vendors) {
      if (!vendor.isEnabled) continue;
      try {
        await action(vendor);
      } catch (e, stack) {
        // One vendor failing must not kill others.
        debugPrint('[monitoring] ${vendor.vendorName} threw: $e\n$stack');
      }
    }
  }

  void _fanoutSync(void Function(AppMonitoringVendor v) action) {
    for (final vendor in _vendors) {
      if (!vendor.isEnabled) continue;
      try {
        action(vendor);
      } catch (e) {
        debugPrint('[monitoring] ${vendor.vendorName} threw: $e');
      }
    }
  }
}
