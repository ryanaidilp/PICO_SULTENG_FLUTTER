import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration, loaded by Flutter before every test file.
///
/// It loads the bundled brand fonts of the UI kit under the names the theme
/// asks for (`packages/pico_ui_kit/...`), so text renders in goldens instead of
/// the Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> load(String family, String file) async {
    final bytes = File('../../packages/pico_ui_kit/assets/fonts/$file')
        .readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  await load('packages/pico_ui_kit/SourceSans3', 'SourceSans3.ttf');

  await testMain();
}
