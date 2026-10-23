import 'package:consent_api/consent_api.dart';
import 'package:test/test.dart';

void main() {
  group('ConsentState fail-closed default', () {
    test('denies every purpose before a decision is recorded', () {
      const state = ConsentState.undecided();

      for (final purpose in ConsentPurpose.values) {
        expect(
          state.isGranted(purpose),
          isFalse,
          reason: '${purpose.storageKey} must be denied while undecided',
        );
        expect(state.hasDecision(purpose), isFalse);
      }
      expect(state.isUndecided, isTrue);
      expect(state.isComplete, isFalse);
    });

    test('a decision on one purpose does not grant any other', () {
      final state = const ConsentState.undecided().withDecision(
        ConsentDecision(
          purpose: ConsentPurpose.analytics,
          granted: true,
          recordedAt: DateTime.utc(2026),
        ),
      );

      expect(state.isGranted(ConsentPurpose.analytics), isTrue);
      expect(state.isGranted(ConsentPurpose.diagnostics), isFalse);
      expect(state.isGranted(ConsentPurpose.marketing), isFalse);
      expect(state.isGranted(ConsentPurpose.targeting), isFalse);
    });

    test('an explicit refusal is distinct from no decision', () {
      final state = const ConsentState.undecided().withDecision(
        ConsentDecision(
          purpose: ConsentPurpose.marketing,
          granted: false,
          recordedAt: DateTime.utc(2026),
        ),
      );

      expect(state.isGranted(ConsentPurpose.marketing), isFalse);
      expect(state.hasDecision(ConsentPurpose.marketing), isTrue);
      expect(state.hasDecision(ConsentPurpose.analytics), isFalse);
    });
  });

  group('DeniedConsentGate', () {
    test('denies everything and reports an undecided state', () {
      const gate = DeniedConsentGate();

      for (final purpose in ConsentPurpose.values) {
        expect(gate.isGranted(purpose), isFalse);
      }
      expect(gate.state.isUndecided, isTrue);
    });

    test('throws rather than silently dropping a recorded decision', () {
      const gate = DeniedConsentGate();

      expect(
        () => gate.record(purpose: ConsentPurpose.analytics, granted: true),
        throwsStateError,
      );
    });
  });

  group('ConsentGateRegistry', () {
    tearDown(ConsentGateRegistry.instance.reset);

    test('hands out a denying gate until one is installed', () {
      expect(ConsentGateRegistry.instance.isInstalled, isFalse);
      expect(ConsentGateRegistry.instance.gate, isA<DeniedConsentGate>());
      expect(
        ConsentGateRegistry.instance.isGranted(ConsentPurpose.analytics),
        isFalse,
      );
    });

    test('install replaces the default', () {
      ConsentGateRegistry.instance.install(
        _FakeGate({ConsentPurpose.targeting}),
      );

      expect(ConsentGateRegistry.instance.isInstalled, isTrue);
      expect(
        ConsentGateRegistry.instance.isGranted(ConsentPurpose.targeting),
        isTrue,
      );
      expect(
        ConsentGateRegistry.instance.isGranted(ConsentPurpose.analytics),
        isFalse,
      );
    });
  });

  group('serialisation', () {
    test('round-trips decisions with timestamp and source', () {
      final recordedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);
      final state = const ConsentState.undecided().withDecisions([
        ConsentDecision(
          purpose: ConsentPurpose.analytics,
          granted: true,
          recordedAt: recordedAt,
          policyVersion: '2026-03-01',
        ),
        ConsentDecision(
          purpose: ConsentPurpose.marketing,
          granted: false,
          recordedAt: recordedAt,
          source: ConsentSource.remoteSync,
        ),
      ]);

      final restored = ConsentState.fromJson(state.toJson());

      expect(restored, equals(state));
      final analytics = restored.decisionFor(ConsentPurpose.analytics)!;
      expect(analytics.granted, isTrue);
      expect(analytics.recordedAt, recordedAt);
      expect(analytics.policyVersion, '2026-03-01');
      expect(analytics.source, ConsentSource.user);
      expect(
        restored.decisionFor(ConsentPurpose.marketing)!.source,
        ConsentSource.remoteSync,
      );
    });

    test('normalises recordedAt to UTC', () {
      final local = DateTime(2026, 3, 14, 9, 26, 53);
      final decision = ConsentDecision(
        purpose: ConsentPurpose.analytics,
        granted: true,
        recordedAt: local,
      );

      expect(decision.recordedAt.isUtc, isTrue);
      expect(decision.recordedAt, local.toUtc());
    });

    test('a corrupt record degrades to undecided, never to granted', () {
      final restored = ConsentState.fromJson(const {
        'decisions': [
          {'purpose': 'analytics', 'granted': 'yes-please'},
          {'purpose': 'not-a-purpose', 'granted': true, 'recorded_at': 'x'},
          'garbage',
        ],
      });

      expect(restored.isUndecided, isTrue);
      for (final purpose in ConsentPurpose.values) {
        expect(restored.isGranted(purpose), isFalse);
      }
    });

    test('an unknown purpose from a newer build is dropped, not fatal', () {
      final restored = ConsentState.fromJson(const {
        'decisions': [
          {
            'purpose': 'analytics',
            'granted': true,
            'recorded_at': '2026-03-14T09:26:53.000Z',
          },
          {
            'purpose': 'purpose_from_the_future',
            'granted': true,
            'recorded_at': '2026-03-14T09:26:53.000Z',
          },
        ],
      });

      expect(restored.isGranted(ConsentPurpose.analytics), isTrue);
      expect(restored.decisions.length, 1);
    });

    test('storage keys are stable and independent of enum names', () {
      expect(ConsentPurpose.analytics.storageKey, 'analytics');
      expect(ConsentPurpose.diagnostics.storageKey, 'diagnostics');
      expect(ConsentPurpose.marketing.storageKey, 'marketing');
      expect(ConsentPurpose.targeting.storageKey, 'targeting');
      expect(ConsentSource.debugOverride.storageKey, 'debug_override');
      expect(
        ConsentPurpose.fromStorageKey('diagnostics'),
        ConsentPurpose.diagnostics,
      );
      expect(ConsentPurpose.fromStorageKey('nope'), isNull);
    });
  });
}

class _FakeGate(final Set<ConsentPurpose> _granted) implements ConsentGate {
  @override
  ConsentState get state => const ConsentState.undecided();

  @override
  bool isGranted(ConsentPurpose purpose) => _granted.contains(purpose);

  @override
  Stream<ConsentState> get changes => const Stream<ConsentState>.empty();

  @override
  Future<void> record({
    required ConsentPurpose purpose,
    required bool granted,
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async {}

  @override
  Future<void> recordAll(
    Map<ConsentPurpose, bool> decisions, {
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
    String? policyVersion,
  }) async {}

  @override
  Future<void> revokeAll({
    ConsentSource source = ConsentSource.user,
    DateTime? recordedAt,
  }) async {}

  @override
  Future<void> clear() async {}
}
