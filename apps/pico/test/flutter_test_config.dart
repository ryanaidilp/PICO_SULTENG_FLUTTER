import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test configuration.
///
/// This file is automatically loaded by Flutter before running any test.
/// Use it to configure global test settings like font loading, default
/// screen sizes, or test-wide setup/teardown.
///
/// See: https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();


  await testMain();
}
