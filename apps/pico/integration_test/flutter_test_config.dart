import 'dart:async';

/// Global integration test configuration.
///
/// This file is automatically loaded by Flutter before running any
/// integration test. Use it for test-wide setup like disabling
/// animations or configuring timeouts.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
