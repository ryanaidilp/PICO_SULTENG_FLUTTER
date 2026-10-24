import 'package:consent_impl/consent_impl.dart';
import 'package:dependencies/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _acme = 'miniapp:acme/rewards';

class _ThrowingStore() implements ScopedConsentStore {
  @override
  Future<List<ScopedConsentDecision>> read() async => throw StateError('x');

  @override
  Future<void> write(List<ScopedConsentDecision> all) async =>
      throw StateError('x');

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PersistedScopedConsentGate newGate([ScopedConsentStore? store]) {
    final gate = PersistedScopedConsentGate(
      store: store ?? InMemoryScopedConsentStore(),
      policyVersion: '1',
    );
    addTearDown(gate.dispose);
    return gate;
  }

  test('denies everything before and after load when undecided', () async {
    final gate = newGate();
    expect(gate.isGranted(_acme, 'identity'), isFalse);
    await gate.load();
    expect(gate.isGranted(_acme, 'identity'), isFalse);
    expect(gate.subjects, isEmpty);
  });

  test('does not grant from storage before load()', () {
    final gate = newGate(
      InMemoryScopedConsentStore(
        initial: [
          ScopedConsentDecision(
            subject: _acme,
            scope: 'identity',
            granted: true,
            recordedAt: DateTime.utc(2026),
          ),
        ],
      ),
    );
    expect(gate.isGranted(_acme, 'identity'), isFalse);
  });

  test('a corrupt store leaves the gate denied', () async {
    final gate = newGate(_ThrowingStore());
    await expectLater(gate.load(), completes);
    expect(gate.isGranted(_acme, 'identity'), isFalse);
  });

  test(
    'recordAll stamps source, policy and record id; emits subject',
    () async {
      final gate = newGate();
      await gate.load();
      final emitted = expectLater(gate.changes, emits(_acme));

      await gate.recordAll(_acme, {
        'identity': true,
        'location': false,
      }, recordId: 'c_1');
      await emitted;

      expect(gate.isGranted(_acme, 'identity'), isTrue);
      expect(gate.isGranted(_acme, 'location'), isFalse);
      final d = gate
          .decisionsFor(_acme)
          .firstWhere((d) => d.scope == 'identity');
      expect(d.policyVersion, '1');
      expect(d.recordId, 'c_1');
      expect(d.source, ConsentSource.user);
      expect(gate.subjects, {_acme});
    },
  );

  test('empty record id from the noop sync is stored as null', () async {
    final gate = newGate();
    await gate.recordAll(_acme, {'a': true}, recordId: '');
    expect(gate.decisionsFor(_acme).single.recordId, isNull);
  });

  test(
    'a later decision replaces the earlier one for the same scope',
    () async {
      final gate = newGate();
      await gate.recordAll(_acme, {'a': true});
      await gate.recordAll(_acme, {'a': false});
      expect(gate.isGranted(_acme, 'a'), isFalse);
      expect(gate.decisionsFor(_acme), hasLength(1));
    },
  );

  test('revokeSubject refuses every scope and leaves the list', () async {
    final gate = newGate();
    await gate.recordAll(_acme, {'a': true, 'b': true});
    await gate.recordAll('miniapp:other/x', {'a': true});

    await gate.revokeSubject(_acme);

    expect(gate.isGranted(_acme, 'a'), isFalse);
    expect(gate.decisionsFor(_acme), hasLength(2)); // audit records stay
    expect(gate.subjects, {'miniapp:other/x'});
  });

  test('putAll from the server overwrites a stale local grant', () async {
    final gate = newGate();
    await gate.recordAll(_acme, {'a': true});
    await gate.putAll([
      ScopedConsentDecision(
        subject: _acme,
        scope: 'a',
        granted: false,
        recordedAt: DateTime.utc(2026, 2),
        source: ConsentSource.remoteSync,
        recordId: 'c_9',
      ),
    ]);
    expect(gate.isGranted(_acme, 'a'), isFalse);
    expect(gate.decisionsFor(_acme).single.source, ConsentSource.remoteSync);
  });

  test('a write failure keeps the in-memory decision', () async {
    final gate = newGate(_ThrowingStore());
    await gate.load();
    await gate.recordAll(_acme, {'a': true});
    expect(gate.isGranted(_acme, 'a'), isTrue);
  });

  test('decisions persist through SharedPreferences and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = newGate(SharedPreferencesScopedConsentStore(prefs));
    await first.load();
    await first.recordAll(_acme, {'identity': true}, recordId: 'c_1');

    final second = newGate(SharedPreferencesScopedConsentStore(prefs));
    await second.load();
    expect(second.isGranted(_acme, 'identity'), isTrue);
    expect(second.decisionsFor(_acme).single.recordId, 'c_1');
  });

  test('scoped store is independent of the purpose store key', () {
    expect(
      SharedPreferencesScopedConsentStore.storageKey,
      isNot(SharedPreferencesConsentStore.storageKey),
    );
  });

  test('a garbled stored entry is dropped, not granted', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesScopedConsentStore.storageKey:
          '[{"subject":1},{"subject":"s","scope":"a","granted":true,'
          '"recorded_at":"2026-01-01T00:00:00Z"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final decisions = await SharedPreferencesScopedConsentStore(prefs).read();
    expect(decisions, hasLength(1));
  });

  group('ConsentInitializer', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ConsentInitializer.reset();
    });
    tearDown(ConsentInitializer.reset);

    test('registers the scoped gate and a noop sync by default', () async {
      final getIt = GetIt.asNewInstance();
      await ConsentInitializer.initialize(getIt);
      expect(getIt<ScopedConsentGate>(), isA<PersistedScopedConsentGate>());
      expect(getIt<ScopedConsentSync>(), isA<NoopScopedConsentSync>());
      expect(ConsentInitializer.scopedGate, isNotNull);
    });
  });
}
