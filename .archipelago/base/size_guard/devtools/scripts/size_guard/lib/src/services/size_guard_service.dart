import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:size_guard/src/models/size_guard_config.dart';

/// Service for scanning files and checking size violations.
class const SizeGuardService({
  /// Root path to scan from.
  required final String rootPath,

  /// Configuration for scanning.
  required final SizeGuardConfig config,
}) {
  /// Creates a new [SizeGuardService].
  this;

  /// Scans for files that exceed the size threshold.
  List<SizeViolation> scan() {
    final violations = <SizeViolation>[];

    try {
      final entities = Directory(rootPath)
          .listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        if (entity is! File) continue;

        final relativePath = p.relative(entity.path, from: rootPath);
        if (_shouldSkipPath(relativePath)) continue;
        if (_matchesIgnorePattern(relativePath)) continue;

        final ext = p.extension(entity.path).toLowerCase();
        if (ext.isEmpty) continue;

        final extWithoutDot = ext.substring(1);
        if (!config.extensions.contains(extWithoutDot)) continue;

        final stat = entity.statSync();
        if (stat.size > config.thresholdBytes) {
          violations.add(
            SizeViolation(
              path: relativePath,
              sizeBytes: stat.size,
              thresholdBytes: config.thresholdBytes,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore permission errors.
    }

    violations.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return violations;
  }

  /// Scans and returns statistics about all matching files.
  ScanStatistics scanWithStats() {
    final violations = <SizeViolation>[];
    var totalFiles = 0;
    var totalBytes = 0;

    try {
      final entities = Directory(rootPath)
          .listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        if (entity is! File) continue;

        final relativePath = p.relative(entity.path, from: rootPath);
        if (_shouldSkipPath(relativePath)) continue;
        if (_matchesIgnorePattern(relativePath)) continue;

        final ext = p.extension(entity.path).toLowerCase();
        if (ext.isEmpty) continue;

        final extWithoutDot = ext.substring(1);
        if (!config.extensions.contains(extWithoutDot)) continue;

        final stat = entity.statSync();
        totalFiles++;
        totalBytes += stat.size;

        if (stat.size > config.thresholdBytes) {
          violations.add(
            SizeViolation(
              path: relativePath,
              sizeBytes: stat.size,
              thresholdBytes: config.thresholdBytes,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore permission errors.
    }

    violations.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return ScanStatistics(
      violations: violations,
      totalFilesScanned: totalFiles,
      totalBytesScanned: totalBytes,
      thresholdBytes: config.thresholdBytes,
    );
  }

  /// Checks only the given [changedFiles] (relative paths) for size violations.
  ///
  /// Use this for PR-scoped checks instead of a full tree scan.
  List<SizeViolation> scanChanged(List<String> changedFiles) {
    final violations = <SizeViolation>[];

    for (final relativePath in changedFiles) {
      if (_matchesIgnorePattern(relativePath)) continue;

      final ext = p.extension(relativePath).toLowerCase();
      if (ext.isEmpty) continue;

      final extWithoutDot = ext.substring(1);
      if (!config.extensions.contains(extWithoutDot)) continue;

      final file = File(p.join(rootPath, relativePath));
      if (!file.existsSync()) continue;

      final stat = file.statSync();
      if (stat.size > config.thresholdBytes) {
        violations.add(
          SizeViolation(
            path: relativePath,
            sizeBytes: stat.size,
            thresholdBytes: config.thresholdBytes,
          ),
        );
      }
    }

    violations.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return violations;
  }

  bool _shouldSkipPath(String relativePath) {
    final segments = p.split(relativePath);
    for (final segment in segments) {
      if (segment.startsWith('.')) return true;
      if (config.ignorePaths.contains(segment)) return true;
    }
    for (final ignorePath in config.ignorePaths) {
      if (relativePath.startsWith(ignorePath)) return true;
    }
    return false;
  }

  bool _matchesIgnorePattern(String relativePath) {
    for (final pattern in config.ignorePatterns) {
      if (_matchesGlob(relativePath, pattern)) return true;
    }
    return false;
  }

  bool _matchesGlob(String path, String pattern) {
    var regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('**', '')
        .replaceAll('*', '[^/]*')
        .replaceAll('', '.*')
        .replaceAll('?', '.');

    regexPattern = '^$regexPattern\$';

    try {
      return RegExp(regexPattern).hasMatch(path);
    } catch (_) {
      return false;
    }
  }
}
