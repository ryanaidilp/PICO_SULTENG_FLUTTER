import 'dart:async';

import 'package:consent_impl/consent_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fail-closed default', () {
    test('denies every purpose before a decision is recorded', () async {
      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();

      expect(gate.state.isUndecided, isTrue);
      for (final purpose in ConsentPurpose.values) {
        expect(
          gate.isGranted(purpose),
          isFalse,
          reason: '${purpose.storageKey} must be denied while undecided',
        );
      }
    });

    test('denies before load() has even run', () {
      final gate = PersistedConsentGate(
        store: InMemoryConsentStore(
          initial: const ConsentState.undecided().withDecision(
            ConsentDecision(
              purpose: ConsentPurpose.analytics,
              granted: true,
              recordedAt: DateTime.utc(2026),
            ),
          ),
        ),
      );
      addTearDown(gate.dispose);

      // Storage says granted, but nothing has been read yet. A telemetry call
      // racing startup must be dropped, not sent optimistically.
      expect(gate.isLoaded, isFalse);
      expect(gate.isGranted(ConsentPurpose.analytics), isFalse);
    });

    test(
      'a corrupt store leaves the gate denied rather than throwing',
      () async {
        final gate = PersistedConsentGate(store: _ThrowingConsentStore());
        addTearDown(gate.dispose);

        await expectLater(gate.load(), completes);
        expect(gate.isGranted(ConsentPurpose.analytics), isFalse);
      },
    );
  });

  group('recording decisions', () {
    test('records per-purpose without granting the others', () async {
      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();

      await gate.record(purpose: ConsentPurpose.analytics, granted: true);

      expect(gate.isGranted(ConsentPurpose.analytics), isTrue);
      expect(gate.isGranted(ConsentPurpose.diagnostics), isFalse);
      expect(gate.isGranted(ConsentPurpose.marketing), isFalse);
      expect(gate.isGranted(ConsentPurpose.targeting), isFalse);
    });

    test('recordAll writes a mixed accept/refuse set', () async {
      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();

      await gate.recordAll({
        ConsentPurpose.analytics: true,
        ConsentPurpose.diagnostics: true,
        ConsentPurpose.marketing: false,
        ConsentPurpose.targeting: false,
      });

      expect(gate.isGranted(ConsentPurpose.analytics), isTrue);
      expect(gate.isGranted(ConsentPurpose.diagnostics), isTrue);
      expect(gate.isGranted(ConsentPurpose.marketing), isFalse);
      expect(gate.state.isComplete, isTrue);
    });

    test('revokeAll refuses every purpose', () async {
      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();
      await gate.recordAll({
        for (final purpose in ConsentPurpose.values) purpose: true,
      });

      await gate.revokeAll();

      for (final purpose in ConsentPurpose.values) {
        expect(gate.isGranted(purpose), isFalse);
        expect(gate.state.hasDecision(purpose), isTrue);
      }
    });

    test('emits the new state on the changes stream', () async {
      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();

      final emitted = <ConsentState>[];
      final subscription = gate.changes.listen(emitted.add);
      addTearDown(subscription.cancel);

      await gate.record(purpose: ConsentPurpose.diagnostics, granted: true);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.isGranted(ConsentPurpose.diagnostics), isTrue);
    });

    test('state changes take effect before persistence completes', () async {
      final slowStore = _SlowConsentStore();
      final gate = PersistedConsentGate(store: slowStore);
      addTearDown(gate.dispose);
      await gate.load();

      final pending = gate.record(
        purpose: ConsentPurpose.analytics,
        granted: false,
      );

      // A refusal must stop telemetry immediately, even if the disk write is
      // still in flight or ultimately fails.
      expect(gate.isGranted(ConsentPurpose.analytics), isFalse);
      slowStore.complete();
      await pending;
    });
  });

  group('cold-start persistence', () {
    test('decisions round-trip across a cold start with a timestamp', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final recordedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);

      final first = PersistedConsentGate(
        store: SharedPreferencesConsentStore(preferences),
        policyVersion: '2026-03-01',
      );
      await first.load();
      await first.recordAll({
        ConsentPurpose.analytics: true,
        ConsentPurpose.marketing: false,
      }, recordedAt: recordedAt);
      await first.dispose();

      // Cold start: a brand new gate over a brand new SharedPreferences
      // handle, as if the process had been killed and relaunched.
      final restored = await SharedPreferences.getInstance();
      final second = PersistedConsentGate(
        store: SharedPreferencesConsentStore(restored),
      );
      addTearDown(second.dispose);
      await second.load();

      expect(second.isGranted(ConsentPurpose.analytics), isTrue);
      expect(second.isGranted(ConsentPurpose.marketing), isFalse);
      expect(second.isGranted(ConsentPurpose.diagnostics), isFalse);

      final decision = second.state.decisionFor(ConsentPurpose.analytics)!;
      expect(decision.recordedAt, recordedAt);
      expect(decision.recordedAt.isUtc, isTrue);
      expect(decision.source, ConsentSource.user);
      expect(decision.policyVersion, '2026-03-01');
    });

    test('clear() erases the persisted record', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final gate = PersistedConsentGate(
        store: SharedPreferencesConsentStore(preferences),
      );
      addTearDown(gate.dispose);
      await gate.load();
      await gate.record(purpose: ConsentPurpose.analytics, granted: true);

      await gate.clear();

      expect(gate.state.isUndecided, isTrue);
      expect(
        preferences.getString(SharedPreferencesConsentStore.storageKey),
        isNull,
      );
    });
  });

  group('debug override', () {
    tearDown(ConsentDebugOverride.reset);

    test('is inactive until explicitly enabled', () async {
      expect(ConsentDebugOverride.isActive, isFalse);

      final gate = PersistedConsentGate(store: InMemoryConsentStore());
      addTearDown(gate.dispose);
      await gate.load();
      await gate.applyDebugOverride();

      expect(gate.state.isUndecided, isTrue);
      expect(gate.isGranted(ConsentPurpose.analytics), isFalse);
    });

    test(
      'grants every purpose once enabled, tagged as a debug override',
      () async {
        ConsentDebugOverride.enable();
        expect(ConsentDebugOverride.isActive, isTrue);

        final gate = PersistedConsentGate(store: InMemoryConsentStore());
        addTearDown(gate.dispose);
        await gate.load();
        await gate.applyDebugOverride();

        for (final purpose in ConsentPurpose.values) {
          expect(gate.isGranted(purpose), isTrue);
          expect(
            gate.state.decisionFor(purpose)!.source,
            ConsentSource.debugOverride,
            reason: 'forced grants must be distinguishable from real consent',
          );
        }
      },
    );

    test('disable() turns a runtime override back off', () {
      ConsentDebugOverride.enable();
      ConsentDebugOverride.disable();

      expect(ConsentDebugOverride.isActive, isFalse);
    });

    test('describes its own state for debug surfaces', () {
      expect(ConsentDebugOverride.description, contains('inactive'));
      expect(
        ConsentDebugOverride.description,
        contains(ConsentDebugOverride.dartDefineKey),
      );

      ConsentDebugOverride.enable();
      expect(ConsentDebugOverride.description, contains('ACTIVE'));
    });

    test('the dart-define is off by default in this test binary', () {
      // Guards against someone flipping the default: the override must be
      // opt-in even in debug builds.
      expect(ConsentDebugOverride.isFromEnvironment, isFalse);
    });
  });
}

class _ThrowingConsentStore() implements ConsentStore {
  @override
  Future<ConsentState?> read() async => throw const FormatException('corrupt');

  @override
  Future<void> write(ConsentState state) async =>
      throw const FormatException('corrupt');

  @override
  Future<void> clear() async {}
}

class _SlowConsentStore() implements ConsentStore {
  final _gate = Completer<void>();

  void complete() => _gate.complete();

  @override
  Future<ConsentState?> read() async => null;

  @override
  Future<void> write(ConsentState state) => _gate.future;

  @override
  Future<void> clear() async {}
}
