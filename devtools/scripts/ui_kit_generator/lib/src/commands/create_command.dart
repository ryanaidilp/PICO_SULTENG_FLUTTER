import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/models/ui_kit_registry.dart';
import 'package:ui_kit_generator/src/registry/layer.dart';

/// Command to create a new custom component scaffold.
class CreateCommand() extends Command<int> {
  /// Creates a new [CreateCommand].
  this {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Component name in kebab-case.',
        mandatory: true,
      )
      ..addOption(
        'layer',
        abbr: 'l',
        help: 'Atomic design layer.',
        allowed: ['atom', 'molecule', 'organism', 'template', 'page'],
        defaultsTo: 'atom',
      )
      ..addMultiOption('dependency', abbr: 'd', help: 'Component dependencies.')
      ..addOption(
        'ui-kit-path',
        help: 'Path to the UI Kit package.',
        defaultsTo: 'packages/pico_ui_kit',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new custom component scaffold.';

  @override
  Future<int> run() async {
    final componentName = argResults!['name'] as String;
    final layerName = argResults!['layer'] as String;
    final dependencies = argResults!['dependency'] as List<String>;
    final logger = CliLogger();

    final layer = Layer.values.firstWhere((l) => l.name == layerName);

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final uiKitPath = argResults!['ui-kit-path'] as String;
      final fullUiKitPath = p.join(rootPath, uiKitPath);
      final registryPath = p.join(fullUiKitPath, 'ui_kit_components.json');

      // Generate the component file.
      final className = _toClassName(componentName);
      final fileName = 'app_${componentName.replaceAll('-', '_')}.dart';
      final componentDir = p.join(
        fullUiKitPath,
        'lib',
        'src',
        'components',
        layer.directory,
        componentName.replaceAll('-', '_'),
      );

      final componentFile = File(p.join(componentDir, fileName));
      await componentFile.parent.create(recursive: true);

      final content = _generateScaffold(className, componentName);
      await componentFile.writeAsString(content);

      logger.success(
        'Created: ${p.relative(componentFile.path, from: rootPath)}',
      );

      // Register the custom component.
      final registry = UiKitRegistry(filePath: registryPath);
      await registry.addCustomComponent({
        'name': componentName,
        'layer': layer.name,
        if (dependencies.isNotEmpty) 'dependencies': dependencies,
      });

      logger.success('Registered custom component: $componentName');

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to create component: $e');
      return 1;
    }
  }

  String _toClassName(String kebabName) => kebabName.split('-').map((part) {
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1);
  }).join();

  String _generateScaffold(String className, String componentName) =>
      '''
import 'package:flutter/widgets.dart';

/// A custom $componentName component.
///
/// TODO: Implement this component.
class App$className extends StatelessWidget {
  /// Creates a new [App$className].
  const App$className({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
}
