import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the UI kit's bundled brand fonts so goldens render real text.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (family, file) in [
    ('packages/pico_ui_kit/SourceSans3', 'SourceSans3.ttf'),
  ]) {
    final bytes = File('../../packages/pico_ui_kit/assets/fonts/$file')
        .readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  await testMain();
}
