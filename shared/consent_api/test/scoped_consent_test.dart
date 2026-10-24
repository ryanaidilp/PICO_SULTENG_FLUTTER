import 'package:consent_api/consent_api.dart';
import 'package:test/test.dart';

void main() {
  test('decision survives a JSON round trip and normalises to UTC', () {
    final d = ScopedConsentDecision(
      subject: 'miniapp:acme/rewards',
      scope: 'identity',
      granted: true,
      recordedAt: DateTime.parse('2026-10-11T10:00:00+07:00'),
      source: ConsentSource.remoteSync,
      policyVersion: '2',
      recordId: 'c_1',
    );
    expect(d.recordedAt.isUtc, isTrue);
    expect(ScopedConsentDecision.fromJson(d.toJson()), d);
  });

  test('fromJson rejects unusable payloads', () {
    expect(ScopedConsentDecision.fromJson({'subject': 's'}), isNull);
    expect(
      ScopedConsentDecision.fromJson({
        'subject': 's',
        'scope': 'x',
        'granted': true,
        'recorded_at': 'nope',
      }),
      isNull,
    );
  });

  test('in-memory store copies on read and write', () async {
    final store = InMemoryScopedConsentStore();
    final list = [
      ScopedConsentDecision(
        subject: 's',
        scope: 'a',
        granted: true,
        recordedAt: DateTime.utc(2026),
      ),
    ];
    await store.write(list);
    list.clear();
    expect(await store.read(), hasLength(1));
    await store.clear();
    expect(await store.read(), isEmpty);
  });

  test('noop sync is local-only and pulls nothing', () async {
    const sync = NoopScopedConsentSync();
    expect(sync.isAvailable, isFalse);
    expect(await sync.push('s', {'a': true}, '1'), isEmpty);
    expect(await sync.pull(), isEmpty);
  });

  test('denied gate denies and refuses to record', () {
    const gate = DeniedScopedConsentGate();
    expect(gate.isGranted('s', 'a'), isFalse);
    expect(gate.subjects, isEmpty);
    expect(() => gate.recordAll('s', {'a': true}), throwsStateError);
  });
}
