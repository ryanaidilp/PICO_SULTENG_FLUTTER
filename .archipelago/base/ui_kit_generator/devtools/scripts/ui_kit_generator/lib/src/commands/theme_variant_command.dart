import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

/// Command to generate theme variant files from config.
class ThemeVariantCommand() extends Command<int> {
  /// Creates a new [ThemeVariantCommand].
  this {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to theme variants YAML config.',
        mandatory: true,
      )
      ..addOption(
        'prefix',
        help: 'Prefix for generated class names.',
        defaultsTo: 'App',
      )
      ..addOption(
        'ui-kit-path',
        help: 'Path to the UI Kit package.',
        defaultsTo: 'packages/pico_ui_kit',
      );
  }

  @override
  String get name => 'theme-variant';

  @override
  String get description => 'Generate theme variant files from config.';

  @override
  Future<int> run() async {
    final configPath = argResults!['config'] as String;
    final prefix = argResults!['prefix'] as String;
    final uiKitPath = argResults!['ui-kit-path'] as String;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final fullConfigPath = p.join(rootPath, configPath);
      final fullUiKitPath = p.join(rootPath, uiKitPath);

      final configFile = File(fullConfigPath);
      if (!configFile.existsSync()) {
        logger.error('Config file not found: $fullConfigPath');
        return 1;
      }

      final content = configFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) {
        logger.error('Invalid YAML config.');
        return 1;
      }

      final variants = yaml['variants'] as YamlList?;
      if (variants == null || variants.isEmpty) {
        logger.info('No theme variants defined in config.');
        return 0;
      }

      final outputDir = p.join(
        fullUiKitPath,
        'lib',
        'src',
        'theme',
        'variants',
      );

      for (final variant in variants) {
        final variantMap = variant as YamlMap;
        final variantName = variantMap['name'] as String;
        final className = _toPascalCase(variantName);

        final fileName =
            '${variantName.replaceAll(RegExp('[^a-z0-9]'), '_')}_theme.dart';
        final outputFile = File(p.join(outputDir, fileName));
        await outputFile.parent.create(recursive: true);

        final generated = _generateThemeVariant(
          prefix: prefix,
          variantName: variantName,
          className: className,
        );

        await outputFile.writeAsString(generated);
        logger.success(
          'Generated: ${p.relative(outputFile.path, from: rootPath)}',
        );
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to generate theme variants: $e');
      return 1;
    }
  }

  String _toPascalCase(String name) =>
      name.split(RegExp(r'[_\-\s]+')).map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      }).join();

  String _generateThemeVariant({
    required String prefix,
    required String variantName,
    required String className,
  }) =>
      '''
import 'package:flutter/material.dart';

/// Theme variant: $variantName
///
/// TODO: Implement color overrides for this theme variant.
class $prefix${className}Theme {
  /// Creates the light variant of the $variantName theme.
  static ThemeData light(ThemeData base) {
    return base.copyWith(
      // Add color overrides here.
    );
  }

  /// Creates the dark variant of the $variantName theme.
  static ThemeData dark(ThemeData base) {
    return base.copyWith(
      // Add color overrides here.
    );
  }
}
''';
}
