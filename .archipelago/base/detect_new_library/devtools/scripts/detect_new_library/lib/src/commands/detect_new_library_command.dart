import 'package:args/command_runner.dart';
import 'package:detect_new_library/src/commands/check_command.dart';

class DetectNewLibraryCommand() extends Command<int> {
  this {
    addSubcommand(CheckCommand());
  }

  @override
  String get name => 'detect-new-library';

  @override
  String get description =>
      'Detect newly added direct dependencies in pubspec.yaml files.';
}
