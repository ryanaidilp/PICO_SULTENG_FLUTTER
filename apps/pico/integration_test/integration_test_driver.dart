import 'package:integration_test/integration_test_driver.dart';

/// Standard integration test driver.
///
/// Use this when running integration tests with `flutter test`:
/// ```bash
/// flutter test integration_test/app_test.dart
/// ```
///
/// For Patrol tests, use `patrol test` instead — it handles
/// the native driver automatically.
Future<void> main() => integrationDriver();
