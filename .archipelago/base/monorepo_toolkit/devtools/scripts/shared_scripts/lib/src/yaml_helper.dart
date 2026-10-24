import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Utilities for reading, writing, and updating YAML files.
class YamlHelper() {
  /// Reads a YAML file at [path] and returns its content as a map.
  ///
  /// Returns an empty map if the file is empty or contains no mappings.
  /// Throws a [FileSystemException] if the file does not exist.
  static Map<String, dynamic> readYaml(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }

    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return {};

    final yaml = loadYaml(content);
    if (yaml is! YamlMap) return {};

    return _yamlMapToMap(yaml);
  }

  /// Writes [data] as YAML to the file at [path].
  ///
  /// Creates the file if it does not exist.
  static void writeYaml(String path, Map<String, dynamic> data) {
    final editor = YamlEditor('');
    editor.update([], data);

    final file = File(path);
    file.writeAsStringSync('$editor\n');
  }

  /// Updates a specific field in a YAML file.
  ///
  /// The [keys] list represents the path to the field
  /// (e.g., `['dependencies', 'http']`).
  ///
  /// ```dart
  /// YamlHelper.updateYamlField(
  ///   'pubspec.yaml',
  ///   ['dependencies', 'http'],
  ///   '^1.0.0',
  /// );
  /// ```
  static void updateYamlField(String path, List<String> keys, dynamic value) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }

    final content = file.readAsStringSync();
    final editor = YamlEditor(content);
    editor.update(keys, value);

    file.writeAsStringSync('$editor\n');
  }

  /// Adds [value] to a YAML list at the specified [keys] path.
  ///
  /// If the value already exists in the list, this is a no-op.
  ///
  /// ```dart
  /// YamlHelper.addToYamlList(
  ///   'pubspec.yaml',
  ///   ['workspace'],
  ///   'packages/new_package',
  /// );
  /// ```
  static void addToYamlList(String path, List<String> keys, String value) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);

    // Navigate to the list
    dynamic current = yaml;
    for (final key in keys) {
      if (current is YamlMap && current.containsKey(key)) {
        current = current[key];
      } else {
        return;
      }
    }

    if (current is! YamlList) return;

    // Check if value already exists
    final existingValues = current.toList().map((e) => e.toString());
    if (existingValues.contains(value)) return;

    final editor = YamlEditor(content);
    editor.appendToList(keys, value);

    file.writeAsStringSync('$editor\n');
  }

  /// Recursively converts a [YamlMap] to a standard [Map].
  static Map<String, dynamic> _yamlMapToMap(YamlMap yamlMap) {
    final map = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlMap) {
        map[key] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        map[key] = _yamlListToList(value);
      } else {
        map[key] = value;
      }
    }
    return map;
  }

  /// Recursively converts a [YamlList] to a standard [List].
  static List<dynamic> _yamlListToList(YamlList yamlList) =>
      yamlList.map((item) {
        if (item is YamlMap) return _yamlMapToMap(item);
        if (item is YamlList) return _yamlListToList(item);
        return item;
      }).toList();
}
