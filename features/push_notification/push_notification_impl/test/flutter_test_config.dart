import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global test configuration, loaded by Flutter before any test in this
/// package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Themes load Google Fonts; a runtime fetch hangs offline (pumpAndSettle
  // times out), so tests fall back to the test font instead.
  GoogleFonts.config.allowRuntimeFetching = false;

  await testMain();
}
