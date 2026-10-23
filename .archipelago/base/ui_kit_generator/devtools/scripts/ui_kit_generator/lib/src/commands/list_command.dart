import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/registry/component_registry.dart';
import 'package:ui_kit_generator/src/registry/layer.dart';

/// Command to list available UI Kit components.
class ListCommand() extends Command<int> {
  /// Creates a new [ListCommand].
  this {
    argParser.addOption(
      'layer',
      abbr: 'l',
      help: 'Filter by layer.',
      allowed: ['atom', 'molecule', 'organism', 'template', 'page'],
    );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List available UI Kit components.';

  @override
  Future<int> run() async {
    final layerFilter = argResults!['layer'] as String?;
    final logger = CliLogger();

    var components = componentRegistry.values.toList();

    if (layerFilter != null) {
      final layer = Layer.values.firstWhere((l) => l.name == layerFilter);
      components = components.where((c) => c.layer == layer).toList();
    }

    if (components.isEmpty) {
      logger.info('No components found.');
      return 0;
    }

    // Group by layer.
    final grouped = <Layer, List<String>>{};
    for (final component in components) {
      grouped.putIfAbsent(component.layer, () => []).add(component.name);
    }

    for (final layer in Layer.values) {
      final names = grouped[layer];
      if (names == null || names.isEmpty) continue;

      logger.info('${layer.name.toUpperCase()} (${names.length}):');
      for (final name in names..sort()) {
        final meta = componentRegistry[name]!;
        logger.info('  $name - ${meta.description}');
      }
      logger.info('');
    }

    logger.info('Total: ${components.length} components');
    return 0;
  }
}
