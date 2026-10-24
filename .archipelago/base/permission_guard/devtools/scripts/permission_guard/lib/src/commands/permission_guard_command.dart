import 'package:args/command_runner.dart';
import 'package:permission_guard/src/commands/android_command.dart';
import 'package:permission_guard/src/commands/ios_command.dart';
import 'package:permission_guard/src/commands/update_baseline_command.dart';

class PermissionGuardCommand() extends Command<int> {
  this {
    addSubcommand(AndroidCommand());
    addSubcommand(IosCommand());
    addSubcommand(UpdateBaselineCommand());
  }

  @override
  String get name => 'permission-guard';

  @override
  String get description =>
      'Extract and diff permissions from compiled APK and IPA artifacts.';
}
