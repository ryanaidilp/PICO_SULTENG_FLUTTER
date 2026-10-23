import 'package:app_marionette/app_marionette.dart' as impl;
import 'package:app_marionette/src/app_binding.dart';
import 'package:app_marionette_noop/app_marionette_noop.dart' as noop;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

typedef _EnsureAppBinding = WidgetsBinding Function({
  bool Function(Element element)? isInteractiveElement,
});

void main() {
  test('impl and noop expose the same ensureAppBinding signature', () {
    // Fails to compile if build-prepare's swap would break the host call.
    const _EnsureAppBinding a = impl.ensureAppBinding;
    const _EnsureAppBinding b = noop.ensureAppBinding;
    expect(a, isNot(same(b)));
  });

  group('useMarionette', () {
    test('a plain debug launch installs Marionette', () {
      expect(useMarionette(environment: {}, bindingInstalled: false), isTrue);
    });

    test('never under flutter test', () {
      expect(
        useMarionette(
          environment: {'FLUTTER_TEST': 'true'},
          bindingInstalled: false,
        ),
        isFalse,
      );
    });

    test('never over an existing binding (integration, Patrol)', () {
      expect(useMarionette(environment: {}, bindingInstalled: true), isFalse);
    });
  });

  testWidgets('under flutter test both keep the test binding', (tester) async {
    expect(impl.ensureAppBinding(), isNot(isA<MarionetteBinding>()));
    expect(noop.ensureAppBinding(), same(WidgetsBinding.instance));
  });
}
