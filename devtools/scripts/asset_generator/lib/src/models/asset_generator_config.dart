import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Configuration for the asset generator.
class const AssetGeneratorConfig({
  /// The path to the package root.
  required final String packagePath,

  /// The path to the assets directory.
  required final String assetsPath,

  /// The path to output generated files.
  required final String outputPath,

  /// The prefix for generated classes.
  required final String prefix,

  /// The package name for asset loading.
  required final String packageName,

  /// The import path for asset_core.
  final String assetCoreImport = 'package:asset_core/asset_core.dart',

  /// The icon category subdirectories to scan.
  final List<String> iconCategories = const <String>[],
}) {
  /// Creates a new [AssetGeneratorConfig].
  this;

  /// Creates config from a YAML file in the package directory.
  factory fromYaml(String packagePath, Map<String, dynamic> yaml) {
    final assetsPath = yaml['assets_path'] as String? ?? 'assets';
    final outputPath = yaml['output_path'] as String? ?? 'lib/src/generated';
    final prefix = yaml['prefix'] as String? ?? 'App';
    final packageName = yaml['package_name'] as String? ?? 'app_asset';
    final assetCoreImport =
        yaml['asset_core_import'] as String? ??
        'package:asset_core/asset_core.dart';

    final iconCategories =
        (yaml['icon_categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return AssetGeneratorConfig(
      packagePath: packagePath,
      assetsPath: p.join(packagePath, assetsPath),
      outputPath: p.join(packagePath, outputPath),
      prefix: prefix,
      packageName: packageName,
      assetCoreImport: assetCoreImport,
      iconCategories: iconCategories,
    );
  }

  /// Loads config from a package directory.
  static AssetGeneratorConfig? load(String packagePath) {
    final configFile = File(p.join(packagePath, 'asset_generator.yaml'));
    if (!configFile.existsSync()) return null;

    final content = configFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;
    if (yaml == null) return null;

    final map = _convertYamlToMap(yaml);
    return AssetGeneratorConfig.fromYaml(packagePath, map);
  }

  static Map<String, dynamic> _convertYamlToMap(YamlMap yaml) {
    final map = <String, dynamic>{};
    for (final key in yaml.keys) {
      final value = yaml[key];
      if (value is YamlMap) {
        map[key.toString()] = _convertYamlToMap(value);
      } else if (value is YamlList) {
        map[key.toString()] = value.toList();
      } else {
        map[key.toString()] = value;
      }
    }
    return map;
  }
}
