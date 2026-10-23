import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Global flavor settings for the entire monorepo.
///
/// This configuration file lives at `flavors.yaml` in the monorepo root
/// and provides a centralized place to manage flavors across all apps.
class GlobalFlavorSettings({
  /// App configurations keyed by app name.
  required final Map<String, AppFlavorSettings> apps,

  /// Default settings for new flavors.
  final FlavorDefaults? defaults,
}) {
  /// Creates a new [GlobalFlavorSettings].
  this;

  /// Creates a [GlobalFlavorSettings] from a YAML file.
  factory fromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return GlobalFlavorSettings(apps: {});
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      return GlobalFlavorSettings(apps: {});
    }

    final appsYaml = yaml['apps'] as YamlMap?;
    final apps = <String, AppFlavorSettings>{};

    if (appsYaml != null) {
      for (final entry in appsYaml.entries) {
        final appName = entry.key as String;
        final appConfig = entry.value as YamlMap?;
        if (appConfig != null) {
          apps[appName] = AppFlavorSettings.fromYaml(appName, appConfig);
        }
      }
    }

    final defaultsYaml = yaml['defaults'] as YamlMap?;
    final defaults = defaultsYaml != null
        ? FlavorDefaults.fromYaml(defaultsYaml)
        : null;

    return GlobalFlavorSettings(apps: apps, defaults: defaults);
  }

  /// Gets the config file path for a monorepo root.
  static String getConfigPath(String rootPath) =>
      path.join(rootPath, 'flavors.yaml');

  /// Saves the settings to a YAML file.
  void save(String filePath) {
    final dir = Directory(path.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final yaml = toYaml();
    final editor = YamlEditor('')..update([], yaml);
    File(filePath).writeAsStringSync(editor.toString());
  }

  /// Adds or updates an app configuration.
  void setApp(String appName, AppFlavorSettings settings) {
    apps[appName] = settings;
  }

  /// Removes an app configuration.
  void removeApp(String appName) {
    apps.remove(appName);
  }

  /// Gets an app configuration.
  AppFlavorSettings? getApp(String appName) => apps[appName];

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    if (defaults != null) 'defaults': defaults!.toYaml(),
    'apps': {for (final entry in apps.entries) entry.key: entry.value.toYaml()},
  };
}

/// Flavor settings for a single app.
class AppFlavorSettings({
  /// The app name.
  required final String name,

  /// List of flavor names for this app.
  required final List<String> flavors,

  /// Base Android application ID.
  final String? androidAppId,

  /// Base iOS bundle identifier.
  final String? iosBundleId,
}) {
  /// Creates a new [AppFlavorSettings].
  this;

  /// Creates an [AppFlavorSettings] from a YAML map.
  factory fromYaml(String name, YamlMap yaml) {
    final flavorsYaml = yaml['flavors'] as YamlList?;
    final flavors = <String>[];

    if (flavorsYaml != null) {
      for (final flavor in flavorsYaml) {
        flavors.add(flavor as String);
      }
    }

    return AppFlavorSettings(
      name: name,
      flavors: flavors,
      androidAppId: yaml['android_app_id'] as String?,
      iosBundleId: yaml['ios_bundle_id'] as String?,
    );
  }

  /// Adds a flavor to this app.
  void addFlavor(String flavorName) {
    if (!flavors.contains(flavorName)) {
      flavors.add(flavorName);
      flavors.sort();
    }
  }

  /// Removes a flavor from this app.
  void removeFlavor(String flavorName) {
    flavors.remove(flavorName);
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    if (androidAppId != null) 'android_app_id': androidAppId,
    if (iosBundleId != null) 'ios_bundle_id': iosBundleId,
    'flavors': flavors,
  };
}

/// Default settings for creating new flavors.
class const FlavorDefaults({
  /// Pattern for bundle ID suffix (e.g., ".{flavor}").
  final String? suffixPattern,

  /// Pattern for app name (e.g., "{app} ({Flavor})").
  final String? appNamePattern,

  /// Default flavors to create for new apps.
  final List<String>? defaultFlavors,
}) {
  /// Creates a new [FlavorDefaults].
  this;

  /// Creates a [FlavorDefaults] from a YAML map.
  factory fromYaml(YamlMap yaml) {
    final defaultFlavorsYaml = yaml['default_flavors'] as YamlList?;

    return FlavorDefaults(
      suffixPattern: yaml['suffix_pattern'] as String?,
      appNamePattern: yaml['app_name_pattern'] as String?,
      defaultFlavors: defaultFlavorsYaml?.cast<String>().toList(),
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() => {
    if (suffixPattern != null) 'suffix_pattern': suffixPattern,
    if (appNamePattern != null) 'app_name_pattern': appNamePattern,
    if (defaultFlavors != null) 'default_flavors': defaultFlavors,
  };
}

/// Cache for tracking flavor generation status.
///
/// This file lives at `.flavor_cache.json` in the monorepo root and tracks
/// which flavors have been generated and their input hashes.
class FlavorGenerationCache({
  /// App generation caches keyed by app name.
  required final Map<String, AppGenerationCache> apps,
}) {
  /// Creates a new [FlavorGenerationCache].
  this;

  /// Creates a [FlavorGenerationCache] from a JSON file.
  factory fromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return FlavorGenerationCache(apps: {});
    }

    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final apps = <String, AppGenerationCache>{};
      final appsJson = json['apps'] as Map<String, dynamic>?;

      if (appsJson != null) {
        for (final entry in appsJson.entries) {
          apps[entry.key] = AppGenerationCache.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          );
        }
      }

      return FlavorGenerationCache(apps: apps);
    } on FormatException {
      return FlavorGenerationCache(apps: {});
    }
  }

  /// Gets the cache file path for a monorepo root.
  static String getCachePath(String rootPath) =>
      path.join(rootPath, '.flavor_cache.json');

  /// Saves the cache to a JSON file.
  void save(String filePath) {
    final json = toJson();
    const encoder = JsonEncoder.withIndent('  ');
    File(filePath).writeAsStringSync(encoder.convert(json));
  }

  /// Gets or creates an app cache.
  AppGenerationCache getOrCreateApp(String appName) =>
      apps.putIfAbsent(appName, () => AppGenerationCache(name: appName));

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'apps': {for (final entry in apps.entries) entry.key: entry.value.toJson()},
  };
}

/// Generation cache for a single app.
class AppGenerationCache({
  /// The app name.
  required final String name,
  Map<String, FlavorGenerationStatus>? flavors,
}) {
  /// Creates a new [AppGenerationCache].
  this;

  /// Creates an [AppGenerationCache] from JSON.
  factory fromJson(String name, Map<String, dynamic> json) {
    final flavorsJson = json['flavors'] as Map<String, dynamic>?;
    final flavors = <String, FlavorGenerationStatus>{};

    if (flavorsJson != null) {
      for (final entry in flavorsJson.entries) {
        flavors[entry.key] = FlavorGenerationStatus.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return AppGenerationCache(name: name, flavors: flavors);
  }

  /// Generation status for each flavor.
  final Map<String, FlavorGenerationStatus> flavors = flavors ?? {};

  /// Updates the generation status for a flavor.
  void updateFlavor(String flavorName, FlavorGenerationStatus status) {
    flavors[flavorName] = status;
  }

  /// Gets the generation status for a flavor.
  FlavorGenerationStatus? getFlavor(String flavorName) => flavors[flavorName];

  /// Checks if a flavor needs regeneration.
  bool needsRegeneration(String flavorName, String currentHash) {
    final status = flavors[flavorName];
    if (status == null) return true;
    return status.inputHash != currentHash;
  }

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'flavors': {
      for (final entry in flavors.entries) entry.key: entry.value.toJson(),
    },
  };
}

/// Generation status for a single flavor.
class const FlavorGenerationStatus({
  /// Hash of the input files used for generation.
  required final String inputHash,

  /// When the flavor was last generated.
  required final DateTime lastGenerated,

  /// List of files generated for this flavor.
  final List<String>? generatedFiles,
}) {
  /// Creates a new [FlavorGenerationStatus].
  this;

  /// Creates a [FlavorGenerationStatus] from JSON.
  factory fromJson(Map<String, dynamic> json) => FlavorGenerationStatus(
    inputHash: json['input_hash'] as String,
    lastGenerated: DateTime.parse(json['last_generated'] as String),
    generatedFiles: (json['generated_files'] as List<dynamic>?)
        ?.cast<String>()
        .toList(),
  );

  /// Converts to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'input_hash': inputHash,
    'last_generated': lastGenerated.toIso8601String(),
    if (generatedFiles != null) 'generated_files': generatedFiles,
  };
}

/// Utility for computing input hashes for flavor generation.
class FlavorHasher() {
  /// Computes a hash for flavor generation inputs.
  static String computeHash({
    required String appPath,
    required String flavorName,
  }) {
    final inputs = <String>[];

    // Add flavorizr.yaml content
    final flavorizrPath = path.join(appPath, 'flavorizr.yaml');
    final flavorizrFile = File(flavorizrPath);
    if (flavorizrFile.existsSync()) {
      inputs.add(flavorizrFile.readAsStringSync());
    }

    // Add launcher icon files
    final launcherDir = Directory(path.join(appPath, 'launcher'));
    if (launcherDir.existsSync()) {
      final iconFiles = launcherDir.listSync().whereType<File>().where(
        (f) => f.path.contains(flavorName) || _isDefaultIcon(f.path),
      );

      for (final file in iconFiles) {
        inputs.add(_fileHash(file));
      }
    }

    // Add splash asset files
    final splashDir = Directory(path.join(appPath, 'splash'));
    if (splashDir.existsSync()) {
      final suffix = _getFlavorSuffix(flavorName);
      final splashFiles = splashDir.listSync().whereType<File>().where((f) {
        final name = path.basename(f.path);
        return name.contains(suffix) || _isDefaultSplash(name);
      });

      for (final file in splashFiles) {
        inputs.add(_fileHash(file));
      }
    }

    // Add flutter_native_splash.yaml content
    final splashConfigPath = path.join(appPath, 'flutter_native_splash.yaml');
    final splashConfigFile = File(splashConfigPath);
    if (splashConfigFile.existsSync()) {
      inputs.add(splashConfigFile.readAsStringSync());
    }

    // Add flavor-specific splash config if exists
    final flavorSplashPath = path.join(
      appPath,
      'flutter_native_splash-$flavorName.yaml',
    );
    final flavorSplashFile = File(flavorSplashPath);
    if (flavorSplashFile.existsSync()) {
      inputs.add(flavorSplashFile.readAsStringSync());
    }

    // Compute combined hash
    final combined = inputs.join('\n---\n');
    return md5.convert(utf8.encode(combined)).toString();
  }

  static String _fileHash(File file) {
    final bytes = file.readAsBytesSync();
    return '${path.basename(file.path)}:${md5.convert(bytes)}';
  }

  static bool _isDefaultIcon(String filePath) {
    final name = path.basename(filePath);
    return name.startsWith('logo') && !name.contains('-');
  }

  static bool _isDefaultSplash(String name) =>
      (name.startsWith('logo') || name.startsWith('branding')) &&
      !name.contains('_dev') &&
      !name.contains('_stg') &&
      !name.contains('_qa');

  static String _getFlavorSuffix(String flavorName) {
    switch (flavorName) {
      case 'development':
        return '_dev';
      case 'staging':
        return '_stg';
      case 'production':
        return '';
      default:
        return '_$flavorName';
    }
  }
}
