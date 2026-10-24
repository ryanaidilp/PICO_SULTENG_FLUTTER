import 'dart:io';

/// The Dart SDK to resolve fixtures against.
///
/// `flutter test` runs on flutter_tester, whose default SDK path has no
/// analyzer metadata (`allowed_experiments.json`), so every fixture fails to
/// resolve. Point at the Dart SDK that Flutter ships instead; `dart test`
/// keeps the default.
String? dartSdkPath() {
  final exe = Platform.resolvedExecutable;
  final i = exe.indexOf('/bin/cache/artifacts/');
  return i < 0 ? null : '${exe.substring(0, i)}/bin/cache/dart-sdk';
}
