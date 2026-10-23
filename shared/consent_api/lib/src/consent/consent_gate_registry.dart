import 'package:consent_api/src/consent/consent_gate.dart';
import 'package:consent_api/src/consent/consent_purpose.dart';
import 'package:dependencies_core/meta.dart';

/// Ambient holder for the app's [ConsentGate].
///
/// Mirrors the existing `FeatureSDKRegistry.instance` /
/// `AnalyticVendorRegistry.instance` singleton-registry convention.
///
/// It exists because some call sites that must be gated are pure value
/// objects with no constructor-injection seam — `EvaluationContext.toMap()`
/// is the motivating example. Everything that *can* take a [ConsentGate] by
/// constructor injection should do so; the registry is the fallback, not the
/// default style.
///
/// Before [install] is called the registry hands out [DeniedConsentGate], so
/// an unwired app is silent rather than leaky.
class ConsentGateRegistry._() {
  /// The process-wide registry.
  static final ConsentGateRegistry instance = ConsentGateRegistry._();

  ConsentGate _gate = const DeniedConsentGate();
  bool _installed = false;

  /// The installed gate, or [DeniedConsentGate] when nothing is installed.
  ConsentGate get gate => _gate;

  /// Whether a real gate has been installed.
  bool get isInstalled => _installed;

  /// Convenience shorthand for `gate.isGranted(purpose)`.
  bool isGranted(ConsentPurpose purpose) => _gate.isGranted(purpose);

  /// Installs the app's gate. Call once during bootstrap, before any
  /// telemetry SDK is initialised.
  void install(ConsentGate gate) {
    _gate = gate;
    _installed = true;
  }

  /// Restores the fail-closed default.
  ///
  /// Intended for tests only — do not call in production code.
  @visibleForTesting
  void reset() {
    _gate = const DeniedConsentGate();
    _installed = false;
  }
}
