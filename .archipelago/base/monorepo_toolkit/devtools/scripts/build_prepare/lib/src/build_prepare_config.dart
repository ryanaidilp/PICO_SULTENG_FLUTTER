import 'dart:io';

import 'package:yaml/yaml.dart';

/// A dependency pair mapping debug package to its release replacement.
class const DependencyMapping({
  /// The debug/development package name (e.g., "monitoring_impl").
  required final String debug,

  /// The release package name (e.g., "monitoring_noop").
  required final String release,

  /// Optional version constraint for debug package.
  final String? debugVersion,

  /// Optional version constraint for release package.
  final String? releaseVersion,

  /// Flavors this mapping applies to. Empty means all flavors
  /// (backward-compatible default).
  final List<String> flavors = const [],
}) {
  /// Creates a new [DependencyMapping].
  this;

  /// Whether this mapping should be applied for [flavor].
  ///
  /// Returns true if [flavor] is null (no filter), [flavors] is empty
  /// (matches everything), or [flavors] contains [flavor].
  bool appliesToFlavor(String? flavor) {
    if (flavor == null) return true;
    if (flavors.isEmpty) return true;
    return flavors.contains(flavor);
  }

  @override
  String toString() => '$debug <-> $release';
}

/// Configuration for the build_prepare tool.
///
/// Reads from a `build_prepare.yaml` file with the following format:
/// ```yaml
/// build_prepare:
///   mappings:
///     - debug: monitoring_impl
///       release: monitoring_noop
///     - debug: app_debugger
///       release: app_debugger_noop
///   target_paths:
///     - apps/template_app
///   internal_flavors: [development, staging, alpha, beta]
///   debug_only:
///     - app_blackbox_metrics
///   debug_build_only:
///     - debug: app_marionette
///       release: app_marionette_noop
///     - marionette_flutter
/// ```
class const BuildPrepareConfig({
  /// Dependency mappings (debug <-> release pairs).
  final List<DependencyMapping> mappings = const [],

  /// Target paths to scan for pubspec.yaml files.
  /// If empty, scans all packages in the workspace.
  final List<String> targetPaths = const [],

  /// Flavors whose builds keep the debug packages. Every other flavor,
  /// including an unknown one, gets the noop twins (ADR-035).
  final List<String> internalFlavors = defaultInternalFlavors,

  /// Packages with no noop twin that must never resolve in a production
  /// build, because only a mapped debug package may reach them (e.g. the
  /// Blackbox capability plugins). Checked by `--check-leaks`.
  final List<String> debugOnly = const [],

  /// Mappings swapped by the build MODE, not the flavor: every release or
  /// profile build gets the noop twin, internal flavors included
  /// (`build-prepare --mode`, ADR-035 amendment). `flavors` is ignored.
  final List<DependencyMapping> debugBuildOnly = const [],

  /// Bare `debug_build_only` entries: packages with no twin that
  /// `--check-leaks` must never find in a release or profile app graph
  /// (e.g. `marionette_flutter`, pulled in only by a mapped package).
  final List<String> debugBuildOnlyPackages = const [],
}) {
  /// Creates a new [BuildPrepareConfig].
  this;

  /// Flavors that keep debug tooling when `internal_flavors` is absent.
  static const defaultInternalFlavors = [
    'development',
    'staging',
    'alpha',
    'beta',
  ];

  /// Whether [flavor] keeps the debug packages.
  bool isInternalFlavor(String flavor) => internalFlavors.contains(flavor);

  /// Loads config from a YAML file at [filePath].
  ///
  /// Returns `null` if the file does not exist or cannot be parsed.
  static BuildPrepareConfig? fromYamlFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      return fromYamlString(file.readAsStringSync());
    } catch (_) {
      return null;
    }
  }

  /// Loads config from a YAML string.
  static BuildPrepareConfig? fromYamlString(String content) {
    try {
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return null;

      final config = yaml['build_prepare'] as YamlMap?;
      if (config == null) return null;

      final mappings = _parseMappings(config['mappings'] as YamlList?);
      final buildModeYaml = config['debug_build_only'] as YamlList?;

      List<String>? stringList(String key) => (config[key] as YamlList?)
          ?.map((e) => e.toString())
          .toList(growable: false);

      return BuildPrepareConfig(
        mappings: mappings,
        targetPaths: stringList('target_paths') ?? const [],
        internalFlavors:
            stringList('internal_flavors') ?? defaultInternalFlavors,
        debugOnly: stringList('debug_only') ?? const [],
        debugBuildOnly: _parseMappings(buildModeYaml),
        debugBuildOnlyPackages: [
          for (final item in buildModeYaml ?? const [])
            if (item is String) item,
        ],
      );
    } catch (_) {
      return null;
    }
  }

  static List<DependencyMapping> _parseMappings(YamlList? yaml) => [
    for (final item in yaml ?? const [])
      if (item is YamlMap &&
          item['debug'] is String &&
          item['release'] is String)
        DependencyMapping(
          debug: item['debug'] as String,
          release: item['release'] as String,
          debugVersion: item['debug_version'] as String?,
          releaseVersion: item['release_version'] as String?,
          flavors:
              (item['flavors'] as YamlList?)
                  ?.map((e) => e.toString())
                  .toList(growable: false) ??
              const [],
        ),
  ];
}
