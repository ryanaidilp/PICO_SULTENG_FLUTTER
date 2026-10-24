// Test support: it deliberately uses @visibleForTesting members.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_prereq/test_prereq.dart';

class _TempPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _TempPaths(this._dir);

  final String _dir;

  @override
  Future<String?> getApplicationSupportPath() async => _dir;

  @override
  Future<String?> getTemporaryPath() async => _dir;
}

/// Lets `initializeInjector()` run under `flutter test`: the module's
/// `@preResolve` calls shared_preferences and path_provider.
class PicoDataImplTestPrerequisite implements TestPrerequisite {
  static String? _dir;

  @override
  String get owner => 'pico_data_impl';

  @override
  String get reason =>
      'PicoDataImplModule @preResolve calls shared_preferences and path_provider.';

  @override
  Future<void> uninstall() async {}

  @override
  Future<void> install() async {
    if (_dir != null) return;
    _dir = Directory.systemTemp.createTempSync('pico_test_').path;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PathProviderPlatform.instance = _TempPaths(_dir!);
  }
}
