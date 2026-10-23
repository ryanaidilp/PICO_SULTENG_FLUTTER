import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Configuration for SVG optimization.
class const SvgConfig({
  final bool enabled = true,
  final List<String> disablePlugins = const [],
}) {
  factory fromYaml(YamlMap? yaml) {
    if (yaml == null) return const SvgConfig();

    return SvgConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      disablePlugins:
          (yaml['disable_plugins'] as YamlList?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Configuration for PNG optimization.
class const PngConfig({
  /// Whether PNG optimization is enabled.
  final bool enabled = true,

  /// Oxipng optimization level (1-6, higher = slower but better).
  final int level = 4,
}) {
  factory fromYaml(YamlMap? yaml) {
    if (yaml == null) return const PngConfig();

    return PngConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      level: yaml['level'] as int? ?? 4,
    );
  }
}

/// Configuration for JPEG optimization.
class const JpegConfig({
  /// Whether JPEG optimization is enabled.
  final bool enabled = true,

  /// JPEG quality (1-100).
  final int quality = 80,
}) {
  factory fromYaml(YamlMap? yaml) {
    if (yaml == null) return const JpegConfig();

    return JpegConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      quality: yaml['quality'] as int? ?? 80,
    );
  }
}

/// Configuration for asset optimization.
class const AssetOptimizerConfig({
  /// Paths to scan for assets.
  final List<String> paths = const [],

  /// SVG optimization configuration.
  final SvgConfig svg = const SvgConfig(),

  /// PNG optimization configuration.
  final PngConfig png = const PngConfig(),

  /// JPEG optimization configuration.
  final JpegConfig jpeg = const JpegConfig(),

  /// Glob patterns to ignore.
  final List<String> ignorePatterns = const [],
}) {
  /// Creates a new [AssetOptimizerConfig].
  this;

  /// Default paths to scan for assets.
  static const defaultPaths = <String>[
    'apps/*/assets',
    'apps/*/*/assets',
    'packages/*/assets',
  ];

  /// Default ignore patterns.
  static const defaultIgnorePatterns = <String>[
    '**/.dart_tool/**',
    '**/build/**',
    '**/.git/**',
    '**/*.9.png',
  ];

  /// Get effective paths (user paths or defaults).
  List<String> get effectivePaths => paths.isNotEmpty ? paths : defaultPaths;

  /// Get effective ignore patterns (defaults + user patterns).
  List<String> get effectiveIgnorePatterns => [
    ...defaultIgnorePatterns,
    ...ignorePatterns,
  ];

  /// Load configuration from a YAML file.
  static AssetOptimizerConfig? fromYamlFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return null;

      final config = yaml['asset_optimizer'] as YamlMap?;
      if (config == null) return null;

      return AssetOptimizerConfig(
        paths:
            (config['paths'] as YamlList?)?.map((e) => e.toString()).toList() ??
            const [],
        svg: SvgConfig.fromYaml(config['svg'] as YamlMap?),
        png: PngConfig.fromYaml(config['png'] as YamlMap?),
        jpeg: JpegConfig.fromYaml(config['jpeg'] as YamlMap?),
        ignorePatterns:
            (config['ignore'] as YamlList?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    } catch (_) {
      return null;
    }
  }

  /// Create a copy with defaults applied.
  AssetOptimizerConfig withDefaults() => AssetOptimizerConfig(
    paths: effectivePaths,
    svg: svg,
    png: png,
    jpeg: jpeg,
    ignorePatterns: effectiveIgnorePatterns,
  );
}

/// Result of optimizing a single file.
class const OptimizationResult({
  /// Path to the file.
  required final String filePath,

  /// Original file size in bytes.
  required final int originalSize,

  /// Optimized file size in bytes.
  required final int optimizedSize,

  /// Whether optimization succeeded.
  required final bool success,

  /// Error message if optimization failed.
  final String? error,
}) {
  /// Creates a new [OptimizationResult].
  this;

  /// Size savings in bytes.
  int get savings => originalSize - optimizedSize;

  /// Reduction percentage.
  double get reductionPercent =>
      originalSize > 0 ? (savings / originalSize) * 100 : 0;

  /// Get relative path from root.
  String relativePath(String rootPath) => p.relative(filePath, from: rootPath);

  String get originalSizeFormatted => formatSize(originalSize);
  String get optimizedSizeFormatted => formatSize(optimizedSize);
  String get savingsFormatted => formatSize(savings);

  /// Format size in human-readable format.
  static String formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Summary of all optimization results.
class const OptimizationSummary({
  required final List<OptimizationResult> results,
}) {
  List<OptimizationResult> get successful =>
      results.where((r) => r.success).toList();

  List<OptimizationResult> get failed =>
      results.where((r) => !r.success).toList();

  int get totalSavings => results.fold(0, (sum, r) => sum + r.savings);

  double get totalReductionPercent {
    final totalOriginal = results.fold(0, (sum, r) => sum + r.originalSize);
    return totalOriginal > 0 ? (totalSavings / totalOriginal) * 100 : 0;
  }

  String get totalSavingsFormatted =>
      OptimizationResult.formatSize(totalSavings);
}
