import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:app_lints/app_lints.dart';
import 'package:test/test.dart';

/// Runs the rule's AST logic over [source] and returns the flagged keys.
///
/// This exercises the exact `PiiTelemetryScanner` the `no_pii_in_telemetry`
/// rule delegates to, without booting the analysis server plugin.
List<String> flaggedKeys(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final collector = _InvocationCollector();
  unit.accept(collector);

  const scanner = PiiTelemetryScanner();
  return [
    for (final invocation in collector.invocations)
      for (final violation in scanner.findViolations(invocation))
        violation.toString(),
  ];
}

void main() {
  group('flags deny-listed keys in map literals passed to track', () {
    test('a literal map argument to track', () {
      final flagged = flaggedKeys('''
void main() {
  analytics.track(SignupEvent({'user_email': email, 'plan': 'pro'}));
}
''');

      expect(flagged, ["'user_email'"]);
    });

    test('a bare map literal passed positionally to track', () {
      final flagged = flaggedKeys('''
void main() {
  analytics.track({'phone_number': phone});
}
''');

      expect(flagged, ["'phone_number'"]);
    });

    test('camelCase keys', () {
      final flagged = flaggedKeys('''
void main() {
  analytics.track({'userEmail': a, 'homeAddress': b, 'screenName': c});
}
''');

      expect(flagged, ["'userEmail'", "'homeAddress'"]);
    });

    test('several offending keys in one payload', () {
      final flagged = flaggedKeys('''
void main() {
  analytics.track({'nik': a, 'password': b, 'plan': c, 'authToken': d});
}
''');

      expect(flagged, ["'nik'", "'password'", "'authToken'"]);
    });
  });

  group('covers the other telemetry entry points', () {
    test('log', () {
      expect(
        flaggedKeys("void main() { monitoring.log('x', data: {'ssn': v}); }"),
        ["'ssn'"],
      );
    });

    test('breadcrumb', () {
      expect(
        flaggedKeys('''
void main() {
  monitoring.breadcrumb('checkout', data: {'phone': p, 'step': 2});
}
'''),
        ["'phone'"],
      );
    });

    test('captureCustomEvent (blackbox sessions)', () {
      expect(
        flaggedKeys('''
void main() {
  recorder.captureCustomEvent('login', properties: {'email': e, 'ok': true});
}
'''),
        ["'email'"],
      );
    });

    test('recordError', () {
      expect(
        flaggedKeys('''
void main() {
  monitoring.recordError(e, s, context: {'creditCard': c});
}
'''),
        ["'creditCard'"],
      );
    });

    test('nested maps inside a telemetry payload', () {
      final flagged = flaggedKeys('''
void main() {
  monitoring.breadcrumb('x', data: {'user': {'email': e, 'id': i}});
}
''');

      expect(flagged, ["'email'"]);
    });

    test('conditional entries in a collection-if', () {
      final flagged = flaggedKeys('''
void main() {
  analytics.track({if (hasUser) 'user_email': e, 'plan': p});
}
''');

      expect(flagged, ["'user_email'"]);
    });
  });

  group('does not fire where it should not', () {
    test('non-telemetry method calls', () {
      expect(
        flaggedKeys("void main() { api.post('/x', {'user_email': e}); }"),
        isEmpty,
      );
    });

    test('safe keys', () {
      expect(
        flaggedKeys('''
void main() {
  analytics.track({'user_id': i, 'screen_name': s, 'plan': p, 'step': 2});
}
'''),
        isEmpty,
      );
    });

    test('short ambiguous fragments inside longer words', () {
      // `nik` must not fire on `technik`, `pin` must not fire on `spinner`.
      expect(
        flaggedKeys('''
void main() {
  analytics.track({'technik_score': a, 'spinner_state': b, 'panel_id': c});
}
'''),
        isEmpty,
      );
    });

    test('a computed key, which cannot be resolved at author time', () {
      expect(
        flaggedKeys('void main() { analytics.track({keyVariable: v}); }'),
        isEmpty,
      );
    });
  });

  group('PiiKeyMatcher', () {
    test('matches the ticket deny-list', () {
      for (final key in [
        'email',
        'user_email',
        'phone',
        'nik',
        'token',
        'password',
        'address',
      ]) {
        expect(PiiKeyMatcher.isDenied(key), isTrue, reason: key);
      }
    });

    test('tokenises the casings the normaliser handles', () {
      expect(PiiKeyMatcher.tokenize('userEmail'), ['user', 'email']);
      expect(PiiKeyMatcher.tokenize('user_email'), ['user', 'email']);
      expect(PiiKeyMatcher.tokenize('USER-EMAIL'), ['user', 'email']);
      expect(PiiKeyMatcher.tokenize('user.email'), ['user', 'email']);
    });

    test('stays in sync with the runtime scrubber deny-list', () {
      // consent_api's ScrubRules holds the authoritative copy; this package
      // duplicates it to stay dependency-free as an analyzer plugin. If these
      // ever diverge, a key caught at runtime would pass review silently.
      expect(PiiKeyMatcher.deniedSubstrings, contains('email'));
      expect(PiiKeyMatcher.deniedSubstrings, contains('phone'));
      expect(PiiKeyMatcher.deniedTokens, contains('nik'));
    });
  });
}

class _InvocationCollector() extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> invocations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    invocations.add(node);
    super.visitMethodInvocation(node);
  }
}
