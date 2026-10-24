import 'package:flutter_test/flutter_test.dart';
import 'package:router_registry/router_registry.dart';

void main() {
  group('ExternalNavigatorImpl', () {
    late ExternalNavigatorImpl navigator;

    setUp(() => navigator = ExternalNavigatorImpl());

    test('starts unattached', () {
      expect(navigator.isAttached, isFalse);
    });

    test('attach flips isAttached to true', () {
      navigator.attach((_) async {});
      expect(navigator.isAttached, isTrue);
    });

    test('navigate before attach throws StateError', () {
      expect(() => navigator.navigate('/home'), throwsStateError);
    });

    test('navigate dispatches to attached handler', () async {
      final calls = <String>[];
      navigator.attach((path) async => calls.add(path));

      await navigator.navigate('/home');
      await navigator.navigate('/profile');

      expect(calls, ['/home', '/profile']);
    });

    test('attach replaces previous handler', () async {
      final firstCalls = <String>[];
      final secondCalls = <String>[];

      navigator.attach((path) async => firstCalls.add(path));
      await navigator.navigate('/a');

      navigator.attach((path) async => secondCalls.add(path));
      await navigator.navigate('/b');

      expect(firstCalls, ['/a']);
      expect(secondCalls, ['/b']);
    });

    test('detach clears the handler', () {
      navigator.attach((_) async {});
      expect(navigator.isAttached, isTrue);

      navigator.detach();

      expect(navigator.isAttached, isFalse);
      expect(() => navigator.navigate('/home'), throwsStateError);
    });

    test('navigate awaits handler completion', () async {
      var completed = false;
      navigator.attach((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        completed = true;
      });

      await navigator.navigate('/home');

      expect(completed, isTrue);
    });
  });
}
