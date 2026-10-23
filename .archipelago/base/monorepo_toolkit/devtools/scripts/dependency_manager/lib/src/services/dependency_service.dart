import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Service for managing dependencies in the shared dependencies package.
class DependencyService({
  /// Path to the dependencies package.
  required final String dependenciesPackagePath,
}) {
  /// Creates a new [DependencyService].
  this;

  /// Gets the path to the pubspec.yaml file.
  String get pubspecPath => path.join(dependenciesPackagePath, 'pubspec.yaml');

  /// Checks if a dependency already exists.
  Future<bool> dependencyExists(String packageName) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) return false;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;
    if (yaml == null) return false;

    final dependencies = yaml['dependencies'] as YamlMap?;
    return dependencies?.containsKey(packageName) ?? false;
  }

  /// Adds a dependency to the pubspec.yaml file.
  Future<void> addDependency({
    required String packageName,
    String? version,
  }) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      throw StateError('pubspec.yaml does not exist at $pubspecPath');
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    // Use version as-is if it already has a constraint operator
    String versionConstraint;
    if (version == null) {
      versionConstraint = 'any';
    } else if (version.startsWith('^') ||
        version.startsWith('>') ||
        version.startsWith('<') ||
        version.startsWith('=')) {
      versionConstraint = version;
    } else {
      versionConstraint = '^$version';
    }

    editor.update(['dependencies', packageName], versionConstraint);

    await pubspecFile.writeAsString(editor.toString());
  }

  /// Removes a dependency from the pubspec.yaml file.
  Future<void> removeDependency({required String packageName}) async {
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      throw StateError('pubspec.yaml does not exist at $pubspecPath');
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    editor.remove(['dependencies', packageName]);

    await pubspecFile.writeAsString(editor.toString());
  }
}
