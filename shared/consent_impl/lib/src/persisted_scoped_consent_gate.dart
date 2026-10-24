import 'dart:async';

import 'package:consent_api/consent_api.dart';
import 'package:flutter/foundation.dart';

/// A [ScopedConsentGate] that keeps decisions in memory and writes every
/// change through to a [ScopedConsentStore].
///
/// Fail-closed like `PersistedConsentGate`: nothing is granted until [load]
/// has read storage, and a storage failure never reads as consent.
class PersistedScopedConsentGate({
  /// Where decisions are persisted.
  required final ScopedConsentStore store,

  /// Version stamped onto decisions that do not carry their own.
  final String? policyVersion,
  DateTime Function()? now,
}) implements ScopedConsentGate {
  /// Creates a gate backed by [store].
  ///
  /// [policyVersion] is stamped onto decisions that do not carry their own.
  this;

  final DateTime Function() _now = now ?? DateTime.now;
  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  // subject -> scope -> latest decision.
  final Map<String, Map<String, ScopedConsentDecision>> _decisions = {};
  bool _loaded = false;

  /// Whether persisted state has been read yet.
  bool get isLoaded => _loaded;

  /// Hydrates from storage. Call once during bootstrap.
  Future<void> load() async {
    if (_loaded) return;
    try {
      for (final d in await store.read()) {
        (_decisions[d.subject] ??= {})[d.scope] = d;
      }
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[consent] failed to restore scoped state: $error\n$stackTrace',
      );
    }
    _loaded = true;
  }

  @override
  bool isGranted(String subject, String scope) =>
      _decisions[subject]?[scope]?.granted ?? false;

  @override
  List<ScopedConsentDecision> decisionsFor(String subject) =>
      List.unmodifiable(_decisions[subject]?.values ?? const []);

  @override
  Set<String> get subjects => {
    for (final entry in _decisions.entries)
      if (entry.value.values.any((d) => d.granted)) entry.key,
  };

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<void> recordAll(
    String subject,
    Map<String, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    String? policyVersion,
    String? recordId,
  }) async {
    final timestamp = _now();
    await _put(subject, [
      for (final entry in decisions.entries)
        ScopedConsentDecision(
          subject: subject,
          scope: entry.key,
          granted: entry.value,
          recordedAt: timestamp,
          source: source,
          policyVersion: policyVersion ?? this.policyVersion,
          // The no-op sync returns '' for "no server record".
          recordId: (recordId?.isEmpty ?? true) ? null : recordId,
        ),
    ]);
  }

  @override
  Future<void> putAll(Iterable<ScopedConsentDecision> decisions) async {
    final bySubject = <String, List<ScopedConsentDecision>>{};
    for (final d in decisions) {
      (bySubject[d.subject] ??= []).add(d);
    }
    for (final entry in bySubject.entries) {
      await _put(entry.key, entry.value);
    }
  }

  @override
  Future<void> revokeSubject(String subject) => recordAll(subject, {
    for (final scope in _decisions[subject]?.keys ?? const <String>[])
      scope: false,
  });

  /// Closes the change stream. Call on app teardown.
  Future<void> dispose() => _changes.close();

  Future<void> _put(String subject, List<ScopedConsentDecision> next) async {
    if (next.isEmpty) return;
    final scopes = _decisions[subject] ??= {};
    for (final d in next) {
      scopes[d.scope] = d;
    }
    // Memory first, so a revoke takes effect even if persistence fails.
    try {
      await store.write([for (final s in _decisions.values) ...s.values]);
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[consent] failed to persist scoped state: $error\n$stackTrace',
      );
    }
    _changes.add(subject);
  }
}
