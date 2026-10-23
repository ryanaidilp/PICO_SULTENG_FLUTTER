import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for coverage management.
class const CoverageConfig({
  /// Global configuration applied to all packages.
  final GlobalCoverageConfig global = const GlobalCoverageConfig(),

  /// Per-package configuration overrides.
  final Map<String, PackageCoverageConfig> packages = const {},
}) {
  /// Creates a new [CoverageConfig].
  this;

  /// Parses configuration from YAML content.
  factory fromYaml(String yamlContent) {
    final yaml = loadYaml(yamlContent) as YamlMap?;
    if (yaml == null) return const CoverageConfig();

    return CoverageConfig(
      global: GlobalCoverageConfig.fromYaml(yaml['global'] as YamlMap?),
      packages: _parsePackages(yaml['packages'] as YamlMap?),
    );
  }

  static Map<String, PackageCoverageConfig> _parsePackages(YamlMap? yaml) {
    if (yaml == null) return {};

    return yaml.map(
      (key, value) => MapEntry(
        key as String,
        PackageCoverageConfig.fromYaml(value as YamlMap?),
      ),
    );
  }

  /// Loads config from a file path.
  static CoverageConfig? fromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      return CoverageConfig.fromYaml(file.readAsStringSync());
    } on Exception {
      return null;
    }
  }

  /// Gets the effective configuration for a specific package.
  EffectiveCoverageConfig getEffectiveConfig(String packageName) {
    final packageConfig = packages[packageName];

    return EffectiveCoverageConfig(
      minLineThreshold:
          packageConfig?.minLineThreshold ?? global.minLineThreshold,
      minBranchThreshold:
          packageConfig?.minBranchThreshold ?? global.minBranchThreshold,
      minFunctionThreshold:
          packageConfig?.minFunctionThreshold ?? global.minFunctionThreshold,
      excludePatterns: [
        ...global.excludePatterns,
        ...?packageConfig?.excludePatterns,
      ],
      excludeFiles: [...global.excludeFiles, ...?packageConfig?.excludeFiles],
      skip: packageConfig?.skip ?? false,
    );
  }

  /// Generates default YAML content.
  static String generateDefault() => '''
# Coverage configuration
# Thresholds are percentages (0-100)

global:
  # Minimum line coverage threshold (default: 80%)
  min_line_threshold: 80

  # Branch and function thresholds apply only when lcov.info has that data
  # (flutter test --branch-coverage writes branches).

  # Minimum branch coverage threshold (default: 70%)
  min_branch_threshold: 70

  # Minimum function coverage threshold (default: 80%)
  min_function_threshold: 80

  # Patterns to exclude from coverage. No "/" matches the file name in any
  # folder; with "/" matches the path from the package root.
  exclude_patterns:
    - "*.g.dart"
    - "*.freezed.dart"
    - "*.config.dart"
    - "*.module.dart"
    - "*.gr.dart"
    - "*.gm.dart"
    - "**/generated/**"

  # Specific files to exclude from coverage
  exclude_files:
    - "lib/main.dart"
    - "lib/main_*.dart"
    - "lib/bootstrap.dart"
    - "lib/app.dart"
    - "**/injector.dart"
    - "**/register_module.dart"

# Per-package configuration (overrides global)
packages:
  # Example package with custom threshold
  # my_package:
  #   min_line_threshold: 90
  #   exclude_patterns:
  #     - "**/legacy/**"
  #   skip: false
''';
}

/// Global coverage configuration.
class const GlobalCoverageConfig({
  /// Minimum line coverage threshold (percentage).
  final double minLineThreshold = 80.0,

  /// Minimum branch coverage threshold (percentage).
  final double minBranchThreshold = 70.0,

  /// Minimum function coverage threshold (percentage).
  final double minFunctionThreshold = 80.0,

  /// Glob patterns to exclude from coverage.
  final List<String> excludePatterns = const [],

  /// Specific files to exclude from coverage.
  final List<String> excludeFiles = const [],
}) {
  /// Creates a new [GlobalCoverageConfig].
  this;

  /// Creates from YAML.
  factory fromYaml(YamlMap? yaml) {
    if (yaml == null) return const GlobalCoverageConfig();

    return GlobalCoverageConfig(
      minLineThreshold: (yaml['min_line_threshold'] as num?)?.toDouble() ?? 80,
      minBranchThreshold:
          (yaml['min_branch_threshold'] as num?)?.toDouble() ?? 70,
      minFunctionThreshold:
          (yaml['min_function_threshold'] as num?)?.toDouble() ?? 80,
      excludePatterns: _parseStringList(yaml['exclude_patterns']),
      excludeFiles: _parseStringList(yaml['exclude_files']),
    );
  }
}

/// Per-package coverage configuration.
class const PackageCoverageConfig({
  /// Minimum line coverage threshold (percentage), overrides global.
  final double? minLineThreshold,

  /// Minimum branch coverage threshold (percentage), overrides global.
  final double? minBranchThreshold,

  /// Minimum function coverage threshold (percentage), overrides global.
  final double? minFunctionThreshold,

  /// Additional patterns to exclude, merged with global.
  final List<String>? excludePatterns,

  /// Additional files to exclude, merged with global.
  final List<String>? excludeFiles,

  /// Whether to skip coverage for this package.
  final bool skip = false,
}) {
  /// Creates a new [PackageCoverageConfig].
  this;

  /// Creates from YAML.
  factory fromYaml(YamlMap? yaml) {
    if (yaml == null) return const PackageCoverageConfig();

    return PackageCoverageConfig(
      minLineThreshold: (yaml['min_line_threshold'] as num?)?.toDouble(),
      minBranchThreshold: (yaml['min_branch_threshold'] as num?)?.toDouble(),
      minFunctionThreshold: (yaml['min_function_threshold'] as num?)
          ?.toDouble(),
      excludePatterns: yaml['exclude_patterns'] != null
          ? _parseStringList(yaml['exclude_patterns'])
          : null,
      excludeFiles: yaml['exclude_files'] != null
          ? _parseStringList(yaml['exclude_files'])
          : null,
      skip: yaml['skip'] as bool? ?? false,
    );
  }
}

/// Effective configuration after merging global and package-specific settings.
class const EffectiveCoverageConfig({
  /// Minimum line coverage threshold.
  required final double minLineThreshold,

  /// Minimum branch coverage threshold.
  required final double minBranchThreshold,

  /// Minimum function coverage threshold.
  required final double minFunctionThreshold,

  /// Patterns to exclude.
  required final List<String> excludePatterns,

  /// Files to exclude.
  required final List<String> excludeFiles,

  /// Whether this package should be skipped.
  required final bool skip,
}) {
  /// Creates a new [EffectiveCoverageConfig].
  this;

  /// All exclusions combined.
  List<String> get allExclusions => [...excludePatterns, ...excludeFiles];
}

/// Coverage result for a package.
class const CoverageResult({
  /// Package name.
  required final String packageName,

  /// Package path.
  required final String packagePath,

  /// Lines covered.
  required final int linesCovered,

  /// Total lines.
  required final int linesTotal,

  /// Branches covered (lcov `BRH`).
  final int branchesCovered = 0,

  /// Total branches (lcov `BRF`); 0 when the report has no branch data.
  final int branchesTotal = 0,

  /// Functions covered (lcov `FNH`).
  final int functionsCovered = 0,

  /// Total functions (lcov `FNF`); 0 when the report has no function data.
  final int functionsTotal = 0,
}) {
  /// Creates a new [CoverageResult].
  this;

  /// Line coverage percentage.
  double get lineCoverage =>
      linesTotal > 0 ? (linesCovered / linesTotal) * 100 : 0;

  /// Branch coverage percentage.
  double get branchCoverage =>
      branchesTotal > 0 ? (branchesCovered / branchesTotal) * 100 : 0;

  /// Function coverage percentage.
  double get functionCoverage =>
      functionsTotal > 0 ? (functionsCovered / functionsTotal) * 100 : 0;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is YamlList) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}
