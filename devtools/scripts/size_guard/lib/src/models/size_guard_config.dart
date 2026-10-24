import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for size guard file scanning.
class const SizeGuardConfig({
  /// File extensions to scan (without dot).
  final Set<String> extensions = defaultExtensions,

  /// Size threshold in bytes.
  final int thresholdBytes = defaultThresholdBytes,

  /// Paths to ignore during scanning.
  final Set<String> ignorePaths = defaultIgnorePaths,

  /// Glob patterns to ignore.
  final List<String> ignorePatterns = const [],
}) {
  /// Creates a new [SizeGuardConfig].
  this;

  /// Default file extensions to scan.
  static const defaultExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'ico',
    'svg',
    'ttf',
    'otf',
    'woff',
    'woff2',
    'mp3',
    'mp4',
    'wav',
    'avi',
    'mov',
    'webm',
    'pdf',
    'zip',
    'tar',
    'gz',
    'rar',
    'json',
    'db',
    'sqlite',
  };

  /// Default size threshold: 500KB in bytes.
  static const defaultThresholdBytes = 500 * 1024;

  /// Default paths to ignore.
  static const defaultIgnorePaths = <String>{
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    'node_modules',
    '.fvm',
    '.pub-cache',
    '.gradle',
    'ios/Pods',
    'android/.gradle',
    'coverage',
  };

  /// Threshold in human-readable format.
  String get thresholdFormatted => formatBytes(thresholdBytes);

  /// Loads config from a YAML file.
  static SizeGuardConfig? fromYamlFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return null;

      final config = yaml['size_guard'] as YamlMap?;
      if (config == null) return null;

      return SizeGuardConfig(
        thresholdBytes:
            parseThreshold(config['threshold'] as String?) ??
            defaultThresholdBytes,
        extensions: _parseStringSet(config['extensions']) ?? defaultExtensions,
        ignorePaths:
            _parseStringSet(config['ignore_paths']) ?? defaultIgnorePaths,
        ignorePatterns: _parseStringList(config['ignore_patterns']) ?? [],
      );
    } catch (_) {
      return null;
    }
  }

  /// Creates a copy with updated values.
  SizeGuardConfig copyWith({
    Set<String>? extensions,
    int? thresholdBytes,
    Set<String>? ignorePaths,
    List<String>? ignorePatterns,
  }) => SizeGuardConfig(
    extensions: extensions ?? this.extensions,
    thresholdBytes: thresholdBytes ?? this.thresholdBytes,
    ignorePaths: ignorePaths ?? this.ignorePaths,
    ignorePatterns: ignorePatterns ?? this.ignorePatterns,
  );

  /// Parses threshold string like "500KB", "1MB", "2GB".
  static int? parseThreshold(String? value) {
    if (value == null) return null;

    final normalized = value.toUpperCase().trim();
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(B|KB|MB|GB)?$')
        .firstMatch(normalized);

    if (match == null) return null;

    final number = double.parse(match.group(1)!);
    final unit = match.group(2) ?? 'B';

    return switch (unit) {
      'B' => number.toInt(),
      'KB' => (number * 1024).toInt(),
      'MB' => (number * 1024 * 1024).toInt(),
      'GB' => (number * 1024 * 1024 * 1024).toInt(),
      _ => number.toInt(),
    };
  }

  static Set<String>? _parseStringSet(dynamic value) {
    if (value == null) return null;
    if (value is YamlList) return value.map((e) => e.toString()).toSet();
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is YamlList) return value.map((e) => e.toString()).toList();
    return null;
  }

  /// Formats bytes in human-readable format.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of a file size violation.
class const SizeViolation({
  /// Path to the file (relative to root).
  required final String path,

  /// Actual file size in bytes.
  required final int sizeBytes,

  /// Threshold that was exceeded.
  required final int thresholdBytes,
}) {
  /// Creates a new [SizeViolation].
  this;

  /// Size in human-readable format.
  String get sizeFormatted => SizeGuardConfig.formatBytes(sizeBytes);

  /// Threshold in human-readable format.
  String get thresholdFormatted => SizeGuardConfig.formatBytes(thresholdBytes);

  /// How much the file exceeds the threshold.
  int get excessBytes => sizeBytes - thresholdBytes;

  /// Excess in human-readable format.
  String get excessFormatted => SizeGuardConfig.formatBytes(excessBytes);
}

/// Statistics from a size guard scan.
class const ScanStatistics({
  /// List of size violations found.
  required final List<SizeViolation> violations,

  /// Total number of files scanned.
  required final int totalFilesScanned,

  /// Total bytes of all scanned files.
  required final int totalBytesScanned,

  /// Threshold used for scanning.
  required final int thresholdBytes,
}) {
  /// Creates new [ScanStatistics].
  this;

  /// Number of violations found.
  int get violationCount => violations.length;

  /// Whether any violations were found.
  bool get hasViolations => violations.isNotEmpty;

  /// Total bytes of all violations.
  int get totalViolationBytes =>
      violations.fold(0, (sum, v) => sum + v.sizeBytes);

  /// Total scanned bytes formatted.
  String get totalBytesFormatted =>
      SizeGuardConfig.formatBytes(totalBytesScanned);

  /// Total violation bytes formatted.
  String get totalViolationBytesFormatted =>
      SizeGuardConfig.formatBytes(totalViolationBytes);
}
