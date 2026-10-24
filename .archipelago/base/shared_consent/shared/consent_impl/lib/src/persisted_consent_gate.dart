import 'dart:async';

import 'package:consent_api/consent_api.dart';
import 'package:consent_impl/src/consent_debug_override.dart';
import 'package:flutter/foundation.dart';

/// A [ConsentGate] that keeps its state in memory and writes every decision
/// through to a [ConsentStore].
///
/// ## Fail-closed contract
///
/// The in-memory state starts at [ConsentState.undecided], so every purpose is
/// denied from the first line of `main()` — including the window before
/// [load] has finished reading storage. A telemetry call that races startup
/// is dropped, never sent optimistically.
///
/// ## Auditability
///
/// Each decision is persisted with its UTC timestamp, the surface it came from
/// and the policy version in force, because being able to prove *when and how*
/// consent was captured is itself a compliance requirement.
class PersistedConsentGate({
  /// Where decisions are persisted.
  required final ConsentStore store,

  /// Version stamped onto decisions that do not carry their own.
  final String? policyVersion,
  DateTime Function()? now,
}) implements ConsentGate {
  /// Creates a gate backed by [store].
  ///
  /// [policyVersion] is stamped onto decisions that do not carry their own,
  /// so an app can detect decisions taken under superseded consent copy and
  /// re-prompt.
  this;

  final DateTime Function() _now = now ?? DateTime.now;
  final StreamController<ConsentState> _changes =
      StreamController<ConsentState>.broadcast();

  ConsentState _state = const ConsentState.undecided();
  bool _loaded = false;

  @override
  ConsentState get state => _state;

  /// Whether persisted state has been read yet.
  bool get isLoaded => _loaded;

  @override
  bool isGranted(ConsentPurpose purpose) => _state.isGranted(purpose);

  @override
  Stream<ConsentState> get changes => _changes.stream;

  /// Hydrates from storage. Call once during bootstrap, before telemetry SDKs
  /// are initialised.
  ///
  /// A storage failure leaves the gate in the undecided (denied) state rather
  /// than throwing — a broken preferences file must not brick app startup, and
  /// must not be interpreted as consent.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final restored = await store.read();
      if (restored != null) _state = restored;
    } on Object catch (error, stackTrace) {
      debugPrint('[consent] failed to restore state: $error\n$stackTrace');
    }
    _loaded = true;
    _changes.add(_state);
  }

  @override
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) => recordAll(
    {purpose: granted},
    source: source,
    recordedAt: recordedAt,
    policyVersion: policyVersion,
  );

  @override
  Future<void> recordAll(
    Map<ConsentPurpose, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async {
    if (decisions.isEmpty) return;
    final timestamp = recordedAt ?? _now();
    final next = _state.withDecisions([
      for (final entry in decisions.entries)
        ConsentDecision(
          purpose: entry.key,
          granted: entry.value,
          recordedAt: timestamp,
          source: source,
          policyVersion: policyVersion ?? this.policyVersion,
        ),
    ]);
    await _commit(next);
  }

  @override
  Future<void> revokeAll({
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
  }) => recordAll(
    {for (final purpose in ConsentPurpose.values) purpose: false},
    source: source,
    recordedAt: recordedAt,
  );

  /// Records a granted decision for every purpose **only** when the debug
  /// override is active.
  ///
  /// Safe to call unconditionally from bootstrap: outside debug builds, and in
  /// debug builds where the override was not requested, this is a no-op.
  /// Decisions it writes are tagged [ConsentSource.debugOverride] so they are
  /// distinguishable from real user consent in `state` and in the debugger.
  Future<void> applyDebugOverride() async {
    if (!ConsentDebugOverride.isActive) return;
    debugPrint('[consent] ${ConsentDebugOverride.description}');
    await recordAll({
      for (final purpose in ConsentPurpose.values) purpose: true,
    }, source: ConsentSource.debugOverride);
  }

  @override
  Future<void> clear() async {
    _state = const ConsentState.undecided();
    try {
      await store.clear();
    } on Object catch (error, stackTrace) {
      debugPrint('[consent] failed to clear state: $error\n$stackTrace');
    }
    _changes.add(_state);
  }

  /// Closes the change stream. Call on app teardown.
  Future<void> dispose() => _changes.close();

  Future<void> _commit(ConsentState next) async {
    _state = next;
    // In-memory state is updated before the write so a purpose refused by the
    // user stops telemetry immediately, even if persistence is slow or fails.
    try {
      await store.write(next);
    } on Object catch (error, stackTrace) {
      debugPrint('[consent] failed to persist state: $error\n$stackTrace');
    }
    _changes.add(next);
  }
}
