import 'dart:async';

import 'package:alchemist/alchemist.dart';

import 'golden_test_helper.dart';

/// Global test configuration that runs before any test.
///
/// This file is automatically detected and executed by the Flutter test runner.
/// It loads fonts  to ensure text
/// renders correctly in golden tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Load fonts from test/fonts/
  await GoldenTestHelper.loadStandardFonts();

  return await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(),
    ),
    run: testMain,
  );
}
