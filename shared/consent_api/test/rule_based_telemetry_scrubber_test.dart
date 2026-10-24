import 'package:consent_api/consent_api.dart';
import 'package:test/test.dart';

void main() {
  late RuleBasedTelemetryScrubber scrubber;

  setUp(() => scrubber = RuleBasedTelemetryScrubber());
  tearDown(() => scrubber.dispose());

  group('deny-listed keys', () {
    test('redacts a property keyed user_email', () {
      final result = scrubber.scrubProperties({
        'user_email': 'someone@example.com',
        'plan': 'pro',
      }, channel: 'analytics');

      expect(result.values['user_email'], '[redacted]');
      expect(result.values['plan'], 'pro');
      expect(result.redactions.single.key, 'user_email');
      expect(result.redactions.single.reason, RedactionReason.deniedKey);
      expect(result.redactions.single.channel, 'analytics');
    });

    test('matches across snake, camel, kebab and dotted casings', () {
      final result = scrubber.scrubProperties({
        'user_email': 'a',
        'userEmail': 'b',
        'USER-EMAIL': 'c',
        'user.email': 'd',
        'phoneNumber': 'e',
        'homeAddress': 'f',
        'authToken': 'g',
        'passwordHash': 'h',
      });

      for (final entry in result.values.entries) {
        expect(entry.value, '[redacted]', reason: 'key ${entry.key}');
      }
      expect(result.redactions.length, 8);
    });

    test('matches short ambiguous tokens only as whole tokens', () {
      final result = scrubber.scrubProperties({
        'nik': '1234',
        'user_nik': '1234',
        'technik_score': 'safe',
        'picnik': 'safe',
        'pin': '9',
        'spinner_state': 'safe',
      });

      expect(result.values['nik'], '[redacted]');
      expect(result.values['user_nik'], '[redacted]');
      expect(result.values['pin'], '[redacted]');
      expect(result.values['technik_score'], 'safe');
      expect(result.values['picnik'], 'safe');
      expect(result.values['spinner_state'], 'safe');
    });
  });

  group('value shapes', () {
    test('redacts a value that is an email address under a benign key', () {
      final result = scrubber.scrubProperties({
        'contact': 'jane.doe+tag@sub.example.co.uk',
      });

      expect(result.values['contact'], '[redacted]');
      expect(result.redactions.single.reason, RedactionReason.emailValue);
    });

    test('redacts long digit runs including separated phone numbers', () {
      final result = scrubber.scrubProperties({
        'a': '+62 812-3456-7890',
        'b': '4111111111111111',
        'c': '3201234567890123',
      });

      expect(result.values.values, everyElement('[redacted]'));
      expect(
        result.redactions.map((r) => r.reason),
        everyElement(RedactionReason.digitRun),
      );
    });

    test('leaves short digit strings and dates alone', () {
      final result = scrubber.scrubProperties({
        'order_no': '12345678',
        'iso_date': '2026-01-15',
        'version': '1.2.3',
        'count': '42',
      });

      expect(result.hasRedactions, isFalse);
      expect(result.values['order_no'], '12345678');
      expect(result.values['iso_date'], '2026-01-15');
    });

    test('does not apply digit-run detection to numeric values', () {
      // A millisecond epoch is 13 digits. Redacting it would strip a
      // timestamp from every event that carries one.
      final result = scrubber.scrubProperties({
        'timestamp_ms': 1735689600000,
        'amount': 9999999999999.99,
        'enabled': true,
      });

      expect(result.hasRedactions, isFalse);
      expect(result.values['timestamp_ms'], 1735689600000);
    });

    test('redacts credential-shaped values', () {
      final result = scrubber.scrubProperties({
        'a': 'Bearer abc123',
        'b': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.dBjftJeZ4CVPmB92K27uhbUJU1p',
        'c': 'sk-Live8fj2Kd91mZq04PxWnT7bYcVa3RgH',
      });

      expect(result.values.values, everyElement('[redacted]'));
      expect(
        result.redactions.map((r) => r.reason),
        everyElement(RedactionReason.bearerToken),
      );
    });

    test('leaves ordinary prose and identifiers alone', () {
      final result = scrubber.scrubProperties({
        'screen_name': 'checkout_summary',
        'message': 'Payment completed successfully',
        'sku': 'ARCH-PRO-2026',
        'locale': 'id_ID',
      });

      expect(result.hasRedactions, isFalse);
    });

    test('leaves UUID session and trace identifiers intact', () {
      // A UUID's final group is 12 hex characters and is often all digits,
      // which a naive digit-run rule would redact — taking the correlation ID
      // out of exactly the events you need it in.
      final result = scrubber.scrubProperties({
        'session_id': '550e8400-e29b-41d4-a716-446655440000',
        'trace_id': '00000000-0000-4000-8000-000000000000',
      });

      expect(result.hasRedactions, isFalse);
      expect(
        result.values['session_id'],
        '550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('leaves ISO timestamps intact', () {
      final result = scrubber.scrubProperties({
        'a': '2026-01-15 10:30:45',
        'b': '2026-01-15T10:30:45.123Z',
      });

      expect(result.hasRedactions, isFalse);
    });
  });

  group('observability', () {
    test('redaction increments an observable counter', () {
      expect(scrubber.redactionCount, 0);

      scrubber.scrubProperties({'user_email': 'a@b.com', 'ok': 'fine'});
      expect(scrubber.redactionCount, 1);

      scrubber.scrubProperties({'contact': 'c@d.com', 'phone': '1'});
      expect(scrubber.redactionCount, 3);

      scrubber.resetRedactionCount();
      expect(scrubber.redactionCount, 0);
    });

    test('emits a record per redaction without ever carrying the value', () {
      final seen = <RedactionRecord>[];
      final subscription = scrubber.redactions.listen(seen.add);
      addTearDown(subscription.cancel);

      scrubber.scrubProperties({
        'user_email': 'secret@example.com',
      }, channel: 'analytics');

      return Future<void>.delayed(Duration.zero, () {
        expect(seen, hasLength(1));
        expect(seen.single.key, 'user_email');
        expect(seen.single.channel, 'analytics');
        expect(seen.single.toString(), isNot(contains('secret@example.com')));
      });
    });

    test('invokes the synchronous onRedaction hook', () {
      final logged = <RedactionRecord>[];
      final logging = RuleBasedTelemetryScrubber(onRedaction: logged.add);
      addTearDown(logging.dispose);

      logging.scrubProperties({'user_email': 'a@b.com'});

      expect(logged, hasLength(1));
      expect(logged.single.reason, RedactionReason.deniedKey);
    });
  });

  group('free text', () {
    test('redacts only the offending span of a log line', () {
      final result = scrubber.scrubText(
        'Checkout failed for jane@example.com on attempt 2',
        channel: 'monitoring',
      );

      expect(result.text, 'Checkout failed for [redacted] on attempt 2');
      expect(result.hasRedactions, isTrue);
      expect(result.redactions.single.reason, RedactionReason.emailValue);
    });

    test('returns clean text untouched', () {
      final result = scrubber.scrubText('Checkout completed in 812 ms');

      expect(result.text, 'Checkout completed in 812 ms');
      expect(result.hasRedactions, isFalse);
    });

    test('preserves whitespace layout while redacting', () {
      final result = scrubber.scrubText('a@b.com\tmiddle  z@y.com');

      expect(result.text, '[redacted]\tmiddle  [redacted]');
      expect(result.redactions, hasLength(2));
    });
  });

  group('nesting and bounds', () {
    test('walks nested maps and lists', () {
      final result = scrubber.scrubProperties({
        'user': {'id': 'u-1', 'email': 'a@b.com'},
        'contacts': ['x@y.com', 'safe'],
      });

      final user = result.values['user']! as Map<String, dynamic>;
      expect(user['id'], 'u-1');
      expect(user['email'], '[redacted]');
      expect(result.values['contacts'], ['[redacted]', 'safe']);
      expect(
        result.redactions.map((r) => r.path),
        containsAll(<String>['user.email', 'contacts']),
      );
    });

    test('redacts beyond max depth rather than descending forever', () {
      final deep = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(maxDepth: 1),
      );
      addTearDown(deep.dispose);

      final result = deep.scrubProperties({
        'a': {
          'b': {'c': 'too deep'},
        },
      });

      final a = result.values['a']! as Map<String, dynamic>;
      expect(a['b'], '[redacted]');
      expect(result.redactions.single.reason, RedactionReason.depthExceeded);
    });

    test('entry budget overflow fails closed', () {
      final bounded = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(maxScannedEntries: 2),
      );
      addTearDown(bounded.dispose);

      final result = bounded.scrubProperties({
        'a': 'one',
        'b': 'two',
        'c': 'three',
        'd': 'four',
      });

      expect(result.values['a'], 'one');
      expect(result.values['b'], 'two');
      expect(result.values['c'], '[redacted]');
      expect(result.values['d'], '[redacted]');
      expect(
        result.redactions.map((r) => r.reason),
        everyElement(RedactionReason.budgetExceeded),
      );
    });

    test('character budget overflow fails closed', () {
      final bounded = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(maxScannedCharacters: 10),
      );
      addTearDown(bounded.dispose);

      final result = bounded.scrubProperties({'a': 'x' * 20, 'b': 'short'});

      expect(result.values['a'], 'x' * 20);
      expect(result.values['b'], '[redacted]');
    });
  });

  group('default-deny mode', () {
    test('redacts every key absent from the allow-list', () {
      final strict = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(allowedKeys: {'screen_name', 'plan'}),
      );
      addTearDown(strict.dispose);

      final result = strict.scrubProperties({
        'screen_name': 'home',
        'plan': 'pro',
        'anything_else': 'value',
      });

      expect(result.values['screen_name'], 'home');
      expect(result.values['plan'], 'pro');
      expect(result.values['anything_else'], '[redacted]');
      expect(result.redactions.single.reason, RedactionReason.notAllowListed);
    });
  });

  group('configurability', () {
    test('digit-run detection can be tuned away from false positives', () {
      // A support-ticket ID that looks like a long digit run is the canonical
      // false positive; apps tune the threshold rather than losing the rule.
      final relaxed = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(digitRunThreshold: 14),
      );
      addTearDown(relaxed.dispose);

      final result = relaxed.scrubProperties({'ticket_id': '1234567890123'});

      expect(result.hasRedactions, isFalse);
      expect(result.values['ticket_id'], '1234567890123');
    });

    test('the redaction marker is configurable', () {
      final custom = RuleBasedTelemetryScrubber(
        rules: const ScrubRules(redactionMarker: '***'),
      );
      addTearDown(custom.dispose);

      final result = custom.scrubProperties({'user_email': 'a@b.com'});

      expect(result.values['user_email'], '***');
    });
  });
}
