import 'package:consent_api/src/consent/consent_purpose.dart';
import 'package:consent_api/src/consent/consent_source.dart';
import 'package:consent_api/src/consent/consent_state.dart';

/// The single choke point every telemetry vendor family consults before
/// dispatching anything off-device.
///
/// [isGranted] is synchronous on purpose: it sits on the analytics/monitoring
/// hot path and must be answerable without awaiting storage. Implementations
/// hydrate persisted state once at startup and keep it in memory.
abstract interface class ConsentGate() {
  /// The current per-purpose state.
  ConsentState get state;

  /// Whether [purpose] is currently granted. Fail-closed: `false` when the
  /// user has not decided.
  bool isGranted(ConsentPurpose purpose);

  /// Emits whenever the state changes. Broadcast; safe for many listeners.
  Stream<ConsentState> get changes;

  /// Persists a decision for a single [purpose].
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source,
    DateTime? recordedAt,
    String? policyVersion,
  });

  /// Persists decisions for several purposes as one atomic write.
  Future<void> recordAll(
    Map<ConsentPurpose, bool> decisions, {
    ConsentSource source,
    DateTime? recordedAt,
    String? policyVersion,
  });

  /// Records a refusal for every purpose (e.g. "reject all" in a consent
  /// sheet, or a data-subject withdrawal request).
  Future<void> revokeAll({ConsentSource source, DateTime? recordedAt});

  /// Erases the stored record entirely, returning to the undecided (denied)
  /// state. Used by "delete my data" flows and by tests.
  Future<void> clear();
}

/// A gate that denies every purpose and cannot record anything.
///
/// This is the default returned by `ConsentGateRegistry` before a real gate is
/// installed, so an app that forgets to wire consent sends no telemetry rather
/// than sending everything.
class const DeniedConsentGate() implements ConsentGate {
  /// Creates the always-denying gate.
  this;

  @override
  ConsentState get state => const ConsentState.undecided();

  @override
  bool isGranted(ConsentPurpose purpose) => false;

  @override
  Stream<ConsentState> get changes => const Stream<ConsentState>.empty();

  @override
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) => throw StateError(_notInstalled);

  @override
  Future<void> recordAll(
    Map<ConsentPurpose, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) => throw StateError(_notInstalled);

  @override
  Future<void> revokeAll({
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
  }) => throw StateError(_notInstalled);

  @override
  Future<void> clear() async {
    // Already empty — clearing an absent record is a no-op, never an error.
  }

  static const String _notInstalled =
      'No ConsentGate is installed. Call '
      'ConsentGateRegistry.instance.install(gate) during bootstrap (see '
      'consent_impl) before recording a consent decision.';
}
