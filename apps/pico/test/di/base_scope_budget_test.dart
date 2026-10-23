// Snapshots what the root container builds at boot.
//
// Every instance `initializeInjector()` builds costs startup time, so the
// list is checked in (`base_scope_budget.txt`) and a change to it is a
// reviewed change. GetIt cannot list registrations that are not built yet,
// so the budget is the built instances (by class name); a lazy registration
// costs nothing at boot and is not in it. Feature global modules that
// register extra root types are caught by the `feature_global_module_allowlist`
// lint instead.
//
// To accept a change on purpose:
//   flutter test --update-goldens test/di/base_scope_budget_test.dart
// and commit the new budget file. With no budget file yet, the test writes
// one locally and passes; in CI it prints a notice and passes.
import 'dart:io';

import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico/di/injector.dart';

import '../support/composition_root_harness.dart';

final _budget = File('test/di/base_scope_budget.txt');

void main() {
  setUpAll(() async {
    await installCompositionRootPrerequisites();
    await initializeInjector();
  });

  tearDownAll(() async {
    await getIt.reset();
    FeatureSDKRegistry.instance.clear();
  });

  test('the root builds only the budgeted instances at boot', () {
    final built =
        getIt.findAll<Object>().map((o) => o.runtimeType.toString()).toList()
          ..sort();
    final actual = '${built.join('\n')}\n';

    if (!_budget.existsSync() && Platform.environment.containsKey('CI')) {
      // No budget committed yet: a fresh project's first CI run must not fail.
      // ignore: avoid_print
      print('${_budget.path} is missing; run this test locally and commit it.');
      return;
    }
    if (!_budget.existsSync() || autoUpdateGoldenFiles) {
      _budget.writeAsStringSync(actual);
      return;
    }

    expect(
      _budget.readAsStringSync(),
      actual,
      reason:
          'The set of instances built by initializeInjector() changed. If '
          'that is intended, run `flutter test --update-goldens '
          'test/di/base_scope_budget_test.dart` and commit '
          '${_budget.path}. If not, make the new registration lazy.',
    );
  });
}
