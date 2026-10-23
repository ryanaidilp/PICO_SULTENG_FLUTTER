import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global test configuration.
///
/// This file is automatically loaded by Flutter before running any test.
/// Use it to configure global test settings like font loading, default
/// screen sizes, or test-wide setup/teardown.
///
/// See: https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The app theme loads Google Fonts; a runtime fetch hangs offline
  // (pumpAndSettle times out), so tests fall back to the test font instead.
  GoogleFonts.config.allowRuntimeFetching = false;

  await testMain();
}
