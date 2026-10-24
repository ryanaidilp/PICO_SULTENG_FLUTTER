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

  // Static instances (400, 600, 700) of the variable brand font: Linux
  // resolves a variable font to its default (ExtraLight) instance, which made
  // text too faint for the contrast checks on CI.
  final loader = FontLoader('packages/pico_ui_kit/SourceSans3');
  for (final w in ['Regular', 'SemiBold', 'Bold']) {
    final bytes = File(
      '../../packages/pico_ui_kit/test/fonts/static/SourceSans3-$w.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();

  await testMain();
}
