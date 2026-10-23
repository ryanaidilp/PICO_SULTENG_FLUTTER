import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for affected packages command.
class const AffectedConfig({
  /// Default base branch to compare against.
  final String baseBranch = 'main',

  /// Predefined commands (name -> command string).
  final Map<String, String> commands = const {},

  /// Packages to always include regardless of changes.
  final List<String> alwaysInclude = const [],

  /// Glob patterns to ignore.
  final List<String> ignore = const [],
}) {
  /// Creates a new [AffectedConfig].
  this;

  /// Parse from YAML map.
  factory fromYaml(YamlMap yaml) {
    final commandsYaml = yaml['commands'] as YamlMap?;
    final commands = <String, String>{};
    if (commandsYaml != null) {
      for (final entry in commandsYaml.entries) {
        commands[entry.key.toString()] = entry.value.toString();
      }
    }

    final alwaysIncludeYaml = yaml['always_include'] as YamlList?;
    final alwaysInclude =
        alwaysIncludeYaml?.map((e) => e.toString()).toList() ?? [];

    final ignoreYaml = yaml['ignore'] as YamlList?;
    final ignore = ignoreYaml?.map((e) => e.toString()).toList() ?? [];

    return AffectedConfig(
      baseBranch: yaml['base_branch']?.toString() ?? 'main',
      commands: commands,
      alwaysInclude: alwaysInclude,
      ignore: ignore,
    );
  }

  /// Load config from YAML file.
  static AffectedConfig? fromYamlFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return null;

      final affected = yaml['affected'] as YamlMap?;
      if (affected == null) return const AffectedConfig();

      return AffectedConfig.fromYaml(affected);
    } on Exception {
      return null;
    }
  }

  /// Apply defaults for common commands.
  AffectedConfig withDefaults() {
    final defaultCommands = <String, String>{
      'analyze': 'flutter analyze lib',
      'test': 'flutter test',
      'format': 'dart format --set-exit-if-changed .',
    };

    return AffectedConfig(
      baseBranch: baseBranch,
      commands: {...defaultCommands, ...commands},
      alwaysInclude: alwaysInclude,
      ignore: ignore.isEmpty
          ? ['devtools/**', '.github/**', '.claude/**']
          : ignore,
    );
  }
}
