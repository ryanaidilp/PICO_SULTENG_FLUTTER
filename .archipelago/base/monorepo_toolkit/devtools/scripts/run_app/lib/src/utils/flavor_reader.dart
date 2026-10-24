import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:run_app/src/models/app_config.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

/// Reads app and flavor configuration from `flavors.yaml` at the workspace root.
class FlavorReader() {
  /// Loads all [AppConfig] entries from `flavors.yaml`.
  ///
  /// Uses [MonorepoFinder] to locate the workspace root, then parses
  /// the `apps:` section of `flavors.yaml`.
  ///
  /// Throws a [FlavorReaderException] if the workspace root cannot be found
  /// or the `flavors.yaml` file does not exist.
  static List<AppConfig> readApps() {
    final String rootPath;
    try {
      rootPath = MonorepoFinder.requireRoot();
      // MonorepoFinder.requireRoot() throws StateError for what is, from
      // this CLI's perspective, an expected/recoverable condition ("not
      // inside a Dart workspace") rather than a programming bug. This is
      // the single translation boundary that converts it to
      // FlavorReaderException, so every other catch of this failure (see
      // run_command.dart) only ever needs to catch an Exception, never an
      // Error subtype.
      // ignore: avoid_catching_errors
    } on StateError catch (e) {
      throw FlavorReaderException(e.message);
    }
    final flavorsFile = File(path.join(rootPath, 'flavors.yaml'));

    if (!flavorsFile.existsSync()) {
      throw FlavorReaderException(
        'flavors.yaml not found at $rootPath. '
        'Run `melos run flavor:generate` to create it.',
      );
    }

    final content = flavorsFile.readAsStringSync();
    final yaml = loadYaml(content);

    if (yaml is! YamlMap) {
      return [];
    }

    final appsNode = yaml['apps'];
    if (appsNode is! YamlMap) {
      return [];
    }

    final configs = <AppConfig>[];
    for (final entry in appsNode.entries) {
      final appName = entry.key as String;
      final appData = entry.value;

      if (appData is! YamlMap) continue;

      final flavorsNode = appData['flavors'];
      final flavors = <String>[];

      if (flavorsNode is YamlList) {
        for (final flavor in flavorsNode) {
          if (flavor is String) {
            flavors.add(flavor);
          }
        }
      }

      if (flavors.isNotEmpty) {
        configs.add(AppConfig(name: appName, flavors: flavors));
      }
    }

    return configs;
  }
}

/// Thrown when [FlavorReader.readApps] cannot locate the monorepo root or
/// `flavors.yaml`.
///
/// Exists so callers catch an [Exception] rather than the [StateError]
/// thrown internally by [MonorepoFinder.requireRoot] — [Error] subtypes are
/// conventionally reserved for programming bugs, not expected/recoverable
/// CLI conditions like "not inside a workspace".
class const FlavorReaderException(
  /// The user-facing error message.
  final String message,
) implements Exception {
  /// Creates a [FlavorReaderException] with a user-facing [message].
  this;

  @override
  String toString() => message;
}
