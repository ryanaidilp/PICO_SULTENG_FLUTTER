import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/models/ui_kit_registry.dart';
import 'package:ui_kit_generator/src/registry/component_registry.dart';

/// Command to show installed UI Kit components.
class StatusCommand() extends Command<int> {
  /// Creates a new [StatusCommand].
  this {
    argParser.addOption(
      'ui-kit-path',
      help: 'Path to the UI Kit package.',
      defaultsTo: 'packages/pico_ui_kit',
    );
  }

  @override
  String get name => 'status';

  @override
  String get description => 'Show installed UI Kit components.';

  @override
  Future<int> run() async {
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final uiKitPath = argResults!['ui-kit-path'] as String;
      final registryPath = p.join(
        rootPath,
        uiKitPath,
        'ui_kit_components.json',
      );

      final registry = UiKitRegistry(filePath: registryPath);
      final installed = await registry.getInstalled();
      final custom = await registry.getCustomComponents();

      if (installed.isEmpty && custom.isEmpty) {
        logger.info('No components installed.');
        return 0;
      }

      if (installed.isNotEmpty) {
        logger.info('Installed components (${installed.length}):');
        for (final name in installed.toList()..sort()) {
          final meta = componentRegistry[name];
          final desc = meta?.description ?? 'custom component';
          logger.info('  $name - $desc');
        }
      }

      if (custom.isNotEmpty) {
        logger.info('');
        logger.info('Custom components (${custom.length}):');
        for (final component in custom) {
          final name = component['name'] as String;
          final layer = component['layer'] as String? ?? 'unknown';
          logger.info('  $name [$layer]');
        }
      }

      logger.info('');
      logger.info(
        'Total: ${installed.length + custom.length} / '
        '${componentRegistry.length} available',
      );

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to get status: $e');
      return 1;
    }
  }
}
