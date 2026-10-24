import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Configuration for Android flavor settings.
class const AndroidFlavorConfig({
  /// The flavor dimension.
  final String flavorDimension = 'app',

  /// The application ID.
  final String? applicationId,

  /// The launcher icon path.
  final String? icon,

  /// The adaptive icon paths (background/foreground).
  final Map<String, String>? adaptiveIcon,
}) {
  /// Creates a new [AndroidFlavorConfig].
  this;

  /// Creates an [AndroidFlavorConfig] from a YAML map.
  factory fromYaml(Map<dynamic, dynamic> yaml) {
    Map<String, String>? adaptiveIcon;
    if (yaml['adaptiveIcon'] != null) {
      final adaptive = yaml['adaptiveIcon'] as Map;
      adaptiveIcon = {
        if (adaptive['background'] != null)
          'background': adaptive['background'] as String,
        if (adaptive['foreground'] != null)
          'foreground': adaptive['foreground'] as String,
      };
    }

    return AndroidFlavorConfig(
      flavorDimension: yaml['flavorDimension'] as String? ?? 'app',
      applicationId: yaml['applicationId'] as String?,
      icon: yaml['icon'] as String?,
      adaptiveIcon: adaptiveIcon,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    'flavorDimension': flavorDimension,
    if (applicationId != null) 'applicationId': applicationId,
    if (icon != null) 'icon': icon,
    if (adaptiveIcon != null) 'adaptiveIcon': adaptiveIcon,
  };
}

/// Configuration for iOS flavor settings.
class const IosFlavorConfig({
  /// The bundle identifier.
  final String? bundleId,

  /// The launcher icon path.
  final String? icon,
}) {
  /// Creates a new [IosFlavorConfig].
  this;

  /// Creates an [IosFlavorConfig] from a YAML map.
  factory fromYaml(Map<dynamic, dynamic> yaml) => IosFlavorConfig(
    bundleId: yaml['bundleId'] as String?,
    icon: yaml['icon'] as String?,
  );

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    if (bundleId != null) 'bundleId': bundleId,
    if (icon != null) 'icon': icon,
  };
}

/// Configuration for app settings within a flavor.
class const AppConfig({
  /// The app display name.
  final String? name,
}) {
  /// Creates a new [AppConfig].
  this;

  /// Creates an [AppConfig] from a YAML map.
  factory fromYaml(Map<dynamic, dynamic> yaml) =>
      AppConfig(name: yaml['name'] as String?);

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {if (name != null) 'name': name};
}

/// Configuration for a single flavor.
class const FlavorConfig({
  /// The flavor name (e.g., 'development', 'staging', 'production').
  required final String name,

  /// The app configuration.
  final AppConfig? app,

  /// The Android-specific configuration.
  final AndroidFlavorConfig? android,

  /// The iOS-specific configuration.
  final IosFlavorConfig? ios,
}) {
  /// Creates a new [FlavorConfig].
  this;

  /// Creates a [FlavorConfig] from a YAML map.
  factory fromYaml(String name, Map<dynamic, dynamic> yaml) => FlavorConfig(
    name: name,
    app: yaml['app'] != null ? AppConfig.fromYaml(yaml['app'] as Map) : null,
    android: yaml['android'] != null
        ? AndroidFlavorConfig.fromYaml(yaml['android'] as Map)
        : null,
    ios: yaml['ios'] != null
        ? IosFlavorConfig.fromYaml(yaml['ios'] as Map)
        : null,
  );

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    if (app != null) 'app': app!.toYaml(),
    if (android != null) 'android': android!.toYaml(),
    if (ios != null) 'ios': ios!.toYaml(),
  };
}

/// Configuration for the entire flavorizr.yaml file.
class FlavorizrConfig({
  /// The flavor configurations.
  required final Map<String, FlavorConfig> flavors,

  /// The flavorizr instructions.
  final List<String>? instructions,
}) {
  /// Creates a new [FlavorizrConfig].
  this;

  /// Creates a [FlavorizrConfig] from a YAML file.
  factory fromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return FlavorizrConfig(flavors: {});
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      return FlavorizrConfig(flavors: {});
    }

    final flavorsYaml = yaml['flavors'] as YamlMap?;
    final flavors = <String, FlavorConfig>{};

    if (flavorsYaml != null) {
      for (final entry in flavorsYaml.entries) {
        final name = entry.key as String;
        final config = entry.value as YamlMap;
        flavors[name] = FlavorConfig.fromYaml(name, config);
      }
    }

    final instructionsYaml = yaml['instructions'] as YamlList?;
    final instructions = instructionsYaml?.cast<String>().toList();

    return FlavorizrConfig(flavors: flavors, instructions: instructions);
  }

  /// Adds a flavor to the configuration and saves to file.
  void addFlavor(String path, FlavorConfig flavor) {
    final file = File(path);
    final content = file.existsSync() ? file.readAsStringSync() : '';
    final editor = YamlEditor(content)
      ..update(['flavors', flavor.name], flavor.toYaml());

    file.writeAsStringSync(editor.toString());
    flavors[flavor.name] = flavor;
  }

  /// Removes a flavor from the configuration and saves to file.
  void removeFlavor(String path, String flavorName) {
    final file = File(path);
    if (!file.existsSync()) return;

    final content = file.readAsStringSync();
    final editor = YamlEditor(content)..remove(['flavors', flavorName]);

    file.writeAsStringSync(editor.toString());
    flavors.remove(flavorName);
  }

  /// Gets the list of flavor names.
  List<String> get flavorNames => flavors.keys.toList()..sort();
}
