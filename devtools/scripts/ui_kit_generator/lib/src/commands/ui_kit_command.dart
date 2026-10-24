import 'package:args/command_runner.dart';
import 'package:ui_kit_generator/src/commands/add_command.dart';
import 'package:ui_kit_generator/src/commands/create_command.dart';
import 'package:ui_kit_generator/src/commands/export_tailwind_command.dart';
import 'package:ui_kit_generator/src/commands/list_command.dart';
import 'package:ui_kit_generator/src/commands/remove_command.dart';
import 'package:ui_kit_generator/src/commands/status_command.dart';

/// Parent command for UI Kit management operations.
class UiKitCommand() extends Command<int> {
  /// Creates a new [UiKitCommand].
  this {
    addSubcommand(ListCommand());
    addSubcommand(AddCommand());
    addSubcommand(RemoveCommand());
    addSubcommand(StatusCommand());
    addSubcommand(CreateCommand());
    addSubcommand(ExportTailwindCommand());
  }

  @override
  String get name => 'ui-kit';

  @override
  String get description => 'Manage UI Kit components.';
}
