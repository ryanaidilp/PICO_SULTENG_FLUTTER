import 'package:consent_api/consent_api.dart';
import 'package:consent_impl/src/default_telemetry_scrubber.dart';
import 'package:consent_impl/src/persisted_consent_gate.dart';
import 'package:consent_impl/src/persisted_scoped_consent_gate.dart';
import 'package:consent_impl/src/shared_preferences_consent_store.dart';
import 'package:consent_impl/src/shared_preferences_scoped_consent_store.dart';
import 'package:dependencies/di.dart';
import 'package:dependencies/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wires the consent gate and telemetry scrubber during bootstrap.
///
/// ## Why this is a pre-launch (blocking) step
///
/// Every telemetry vendor family asks the gate before dispatching. If the gate
/// is installed *after* the first tracked event, that event escapes the check.
/// Consent therefore belongs in the blocking pre-launch phase alongside DI and
/// route registration — not in the non-blocking post-launch phase with the
/// analytics vendors it governs.
///
/// It is deliberately a plain initializer rather than an injectable
/// micro-package module: the gate must be hydrated from storage (`await`) and
/// installed into the ambient registries before anything resolves
/// `AppMonitoring` or `AnalyticTracker`, which a lazy DI registration cannot
/// guarantee.
///
/// ```dart
/// await ConsentInitializer.initialize(getIt);
/// ```
abstract final class ConsentInitializer() {
  static PersistedConsentGate? _gate;
  static PersistedScopedConsentGate? _scopedGate;

  /// The gate created by [initialize], or `null` before it runs.
  static PersistedConsentGate? get gate => _gate;

  /// The mini-app gate created by [initialize], or `null` before it runs.
  static PersistedScopedConsentGate? get scopedGate => _scopedGate;

  /// Whether [initialize] has completed.
  static bool get isInitialized => _gate != null;

  /// Creates, hydrates and installs the consent gate and telemetry scrubber.
  ///
  /// Pass [rules] to tune redaction per app, [policyVersion] to stamp the
  /// consent copy version onto new decisions, and [store] to substitute
  /// storage (tests, encrypted preferences, a server-backed record).
  ///
  /// [scopedStore] and [scopedSync] do the same for per-mini-app grants.
  /// Without a [scopedSync] consent stays on the device. Both are registered
  /// in [getIt] next to [ConsentGate]; nothing reads them unless the partner
  /// mini-app SDK is present.
  static Future<void> initialize(
    GetIt getIt, {
    ScrubRules rules = const ScrubRules(),
    String? policyVersion,
    ConsentStore? store,
    ScopedConsentStore? scopedStore,
    ScopedConsentSync? scopedSync,
  }) async {
    if (_gate != null) return;

    final preferences = await SharedPreferences.getInstance();
    final resolvedStore = store ?? SharedPreferencesConsentStore(preferences);

    final gate = PersistedConsentGate(
      store: resolvedStore,
      policyVersion: policyVersion,
    );
    await gate.load();
    // No-op unless this is a debug build launched with the override; see
    // ConsentDebugOverride for why the escape hatch is shaped this way.
    await gate.applyDebugOverride();

    final scoped = PersistedScopedConsentGate(
      store: scopedStore ?? SharedPreferencesScopedConsentStore(preferences),
    );
    await scoped.load();

    final scrubber = DefaultTelemetryScrubber(rules: rules);

    ConsentGateRegistry.instance.install(gate);
    TelemetryScrubberRegistry.instance.install(scrubber);

    if (!getIt.isRegistered<ConsentGate>()) {
      getIt.registerSingleton<ConsentGate>(gate);
    }
    if (!getIt.isRegistered<TelemetryScrubber>()) {
      getIt.registerSingleton<TelemetryScrubber>(scrubber);
    }
    if (!getIt.isRegistered<ScopedConsentGate>()) {
      getIt.registerSingleton<ScopedConsentGate>(scoped);
    }
    if (!getIt.isRegistered<ScopedConsentSync>()) {
      getIt.registerSingleton<ScopedConsentSync>(
        scopedSync ?? const NoopScopedConsentSync(),
      );
    }

    _gate = gate;
    _scopedGate = scoped;
  }

  /// Resets initialization state and the ambient registries.
  ///
  /// Intended for testing only — do not call in production code.
  @visibleForTesting
  static Future<void> reset() async {
    await _gate?.dispose();
    await _scopedGate?.dispose();
    _gate = null;
    _scopedGate = null;
    // This method is itself @visibleForTesting, so forwarding to the
    // registries' test-only resets is the intended use, not a leak of test
    // hooks into production code.
    // ignore: invalid_use_of_visible_for_testing_member
    ConsentGateRegistry.instance.reset();
    // See the note above: test-only reset forwarded from a test-only method.
    // ignore: invalid_use_of_visible_for_testing_member
    TelemetryScrubberRegistry.instance.reset();
  }
}
