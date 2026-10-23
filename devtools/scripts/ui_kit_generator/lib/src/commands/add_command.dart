import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/models/ui_kit_registry.dart';
import 'package:ui_kit_generator/src/registry/component_registry.dart';

/// Command to add a component to the UI Kit.
class AddCommand() extends Command<int> {
  /// Creates a new [AddCommand].
  this {
    argParser.addOption(
      'ui-kit-path',
      help: 'Path to the UI Kit package.',
      defaultsTo: 'packages/pico_ui_kit',
    );
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Add a component to the UI Kit.';

  @override
  String get invocation => 'ui-kit add <component-name>';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final args = argResults!.rest;

    if (args.isEmpty) {
      logger.error('Please specify a component name.');
      logger.info('Available components: ${componentRegistry.keys.join(', ')}');
      return 64;
    }

    final componentName = args.first;

    if (!componentRegistry.containsKey(componentName)) {
      logger.error('Unknown component: $componentName');
      logger.info('Available components: ${componentRegistry.keys.join(', ')}');
      return 1;
    }

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final uiKitPath = argResults!['ui-kit-path'] as String;
      final registryPath = p.join(
        rootPath,
        uiKitPath,
        'ui_kit_components.json',
      );

      final registry = UiKitRegistry(filePath: registryPath);

      if (await registry.isInstalled(componentName)) {
        logger.info('Component "$componentName" is already installed.');
        return 0;
      }

      // Also add dependencies.
      final meta = componentRegistry[componentName]!;
      final toInstall = <String>[componentName];
      for (final dep in meta.dependencies) {
        if (!await registry.isInstalled(dep)) {
          toInstall.add(dep);
        }
      }

      for (final name in toInstall) {
        await registry.addInstalled(name);
        logger.success('Added: $name');
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to add component: $e');
      return 1;
    }
  }
}
