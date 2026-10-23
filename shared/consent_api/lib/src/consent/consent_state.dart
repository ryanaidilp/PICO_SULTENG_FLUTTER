import 'package:consent_api/src/consent/consent_decision.dart';
import 'package:consent_api/src/consent/consent_purpose.dart';
import 'package:dependencies_core/meta.dart';

/// The current per-purpose consent state.
///
/// **Fail closed:** a purpose with no recorded decision is denied. There is no
/// "unknown → allow" path; [isGranted] returns `false` for anything absent.
@immutable
class ConsentState {
  /// Creates a state from an explicit decision map.
  const new(Map<ConsentPurpose, ConsentDecision> decisions)
    : _decisions = decisions;

  /// The initial state: nothing decided, therefore everything denied.
  const new undecided() : _decisions = const {};

  /// Rehydrates a state from [toJson] output.
  ///
  /// Malformed entries are dropped rather than throwing — a corrupt store
  /// degrades to "undecided" (denied), never to "granted".
  factory fromJson(Map<String, dynamic> json) {
    final raw = json['decisions'];
    if (raw is! List) return const ConsentState.undecided();

    final decisions = <ConsentPurpose, ConsentDecision>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final decision = ConsentDecision.fromJson(
        entry.map((key, value) => MapEntry('$key', value)),
      );
      if (decision != null) decisions[decision.purpose] = decision;
    }
    return ConsentState(decisions);
  }

  final Map<ConsentPurpose, ConsentDecision> _decisions;

  /// All recorded decisions, keyed by purpose.
  Map<ConsentPurpose, ConsentDecision> get decisions =>
      Map<ConsentPurpose, ConsentDecision>.unmodifiable(_decisions);

  /// Whether [purpose] is granted. Absent decisions are denied.
  bool isGranted(ConsentPurpose purpose) =>
      _decisions[purpose]?.granted ?? false;

  /// The recorded decision for [purpose], or `null` if the user has not
  /// decided yet.
  ConsentDecision? decisionFor(ConsentPurpose purpose) => _decisions[purpose];

  /// Whether [purpose] has any recorded decision (granted or refused).
  bool hasDecision(ConsentPurpose purpose) => _decisions.containsKey(purpose);

  /// Whether nothing has been decided at all.
  bool get isUndecided => _decisions.isEmpty;

  /// Whether every purpose has a recorded decision.
  bool get isComplete => _decisions.length == ConsentPurpose.values.length;

  /// Returns a copy with [decision] applied.
  ConsentState withDecision(ConsentDecision decision) =>
      ConsentState({..._decisions, decision.purpose: decision});

  /// Returns a copy with every decision in [newDecisions] applied.
  ConsentState withDecisions(Iterable<ConsentDecision> newDecisions) =>
      ConsentState({
        ..._decisions,
        for (final decision in newDecisions) decision.purpose: decision,
      });

  /// Serialises the state for persistence.
  Map<String, dynamic> toJson() => {
    'decisions': [for (final decision in _decisions.values) decision.toJson()],
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConsentState || runtimeType != other.runtimeType) {
      return false;
    }
    if (_decisions.length != other._decisions.length) return false;
    for (final entry in _decisions.entries) {
      if (other._decisions[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _decisions.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  @override
  String toString() {
    final parts = ConsentPurpose.values.map((purpose) {
      final decision = _decisions[purpose];
      if (decision == null) return '${purpose.storageKey}=undecided';
      return '${purpose.storageKey}=${decision.granted}';
    });
    return 'ConsentState(${parts.join(', ')})';
  }
}
