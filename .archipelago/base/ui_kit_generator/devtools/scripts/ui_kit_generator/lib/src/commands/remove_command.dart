import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/models/ui_kit_registry.dart';

/// Command to remove a component from the UI Kit.
class RemoveCommand() extends Command<int> {
  /// Creates a new [RemoveCommand].
  this {
    argParser.addOption(
      'ui-kit-path',
      help: 'Path to the UI Kit package.',
      defaultsTo: 'packages/pico_ui_kit',
    );
  }

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove a component from the UI Kit.';

  @override
  String get invocation => 'ui-kit remove <component-name>';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final args = argResults!.rest;

    if (args.isEmpty) {
      logger.error('Please specify a component name.');
      return 64;
    }

    final componentName = args.first;

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final uiKitPath = argResults!['ui-kit-path'] as String;
      final registryPath = p.join(
        rootPath,
        uiKitPath,
        'ui_kit_components.json',
      );

      final registry = UiKitRegistry(filePath: registryPath);

      if (!await registry.isInstalled(componentName)) {
        logger.info('Component "$componentName" is not installed.');
        return 0;
      }

      await registry.removeInstalled(componentName);
      logger.success('Removed: $componentName');

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to remove component: $e');
      return 1;
    }
  }
}
