import 'dart:io';

import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';
import 'package:asset_optimizer/src/services/optimizers/jpeg_optimizer.dart';
import 'package:asset_optimizer/src/services/optimizers/optimizer.dart';
import 'package:asset_optimizer/src/services/optimizers/png_optimizer.dart';
import 'package:asset_optimizer/src/services/optimizers/svg_optimizer.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Service for finding and optimizing assets in the monorepo.
class AssetOptimizerService({
  /// Root path of the monorepo.
  required final String rootPath,

  /// Configuration.
  required final AssetOptimizerConfig config,
  CliLogger? logger,
}) {
  /// Creates a new [AssetOptimizerService].
  this {
    _optimizers = [
      if (config.svg.enabled) SvgOptimizer(config: config.svg),
      if (config.png.enabled) PngOptimizer(config: config.png),
      if (config.jpeg.enabled) JpegOptimizer(config: config.jpeg),
    ];
  }

  final CliLogger _logger = logger ?? CliLogger();
  late final List<Optimizer> _optimizers;

  /// All active optimizers.
  List<Optimizer> get optimizers => _optimizers;

  /// Check which tools are installed.
  Future<Map<String, bool>> checkTools() async {
    final results = <String, bool>{};
    for (final optimizer in _optimizers) {
      results[optimizer.name] = await optimizer.isInstalled();
    }
    return results;
  }

  /// Get missing tools with install instructions.
  Future<Map<String, String>> getMissingTools() async {
    final missing = <String, String>{};
    for (final optimizer in _optimizers) {
      if (!await optimizer.isInstalled()) {
        missing[optimizer.name] = optimizer.installInstructions;
      }
    }
    return missing;
  }

  /// Find all asset files that can be optimized.
  List<File> findAssets() {
    final files = <File>[];

    for (final pattern in config.effectivePaths) {
      final matchingDirs = _findMatchingDirectories(
        rootPath,
        pattern.split('/'),
      );

      for (final dir in matchingDirs) {
        if (!dir.existsSync()) continue;

        final entities = dir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is! File) continue;
          if (_shouldIgnore(entity.path)) continue;

          for (final optimizer in _optimizers) {
            if (optimizer.supportsFile(entity)) {
              files.add(entity);
              break;
            }
          }
        }
      }
    }

    final uniquePaths = files.map((f) => f.path).toSet();
    return uniquePaths.map(File.new).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Optimize or report on all found assets.
  ///
  /// If [files] is provided, it is used instead of re-scanning the asset
  /// tree via [findAssets] — callers that already called [findAssets]
  /// (e.g. to report a count before optimizing) should pass that result
  /// here to avoid a redundant directory walk.
  Future<OptimizationSummary> optimizeAll({
    bool dryRun = false,
    List<File>? files,
  }) async {
    files ??= findAssets();
    final results = <OptimizationResult>[];

    for (final file in files) {
      final relativePath = p.relative(file.path, from: rootPath);
      final originalSize = file.lengthSync();

      if (dryRun) {
        results.add(
          OptimizationResult(
            filePath: file.path,
            originalSize: originalSize,
            optimizedSize: originalSize,
            success: true,
          ),
        );
        _logger.info(
          '  [dry-run] $relativePath (${OptimizationResult.formatSize(originalSize)})',
        );
        continue;
      }

      final optimizer = _getOptimizerForFile(file);
      if (optimizer == null) continue;

      final result = await optimizer.optimize(file);
      results.add(result);

      if (result.success) {
        if (result.savings > 0) {
          _logger.success(
            '  $relativePath: '
            '${result.originalSizeFormatted} -> ${result.optimizedSizeFormatted} '
            '(${result.reductionPercent.toStringAsFixed(0)}% reduction)',
          );
        } else {
          _logger.info('  $relativePath: already optimized');
        }
      } else {
        _logger.error('  $relativePath: ${result.error}');
      }
    }

    return OptimizationSummary(results: results);
  }

  Optimizer? _getOptimizerForFile(File file) {
    for (final optimizer in _optimizers) {
      if (optimizer.supportsFile(file)) return optimizer;
    }
    return null;
  }

  List<Directory> _findMatchingDirectories(String root, List<String> parts) {
    var currentDirs = [Directory(root)];

    for (final part in parts) {
      final nextDirs = <Directory>[];

      for (final dir in currentDirs) {
        if (!dir.existsSync()) continue;

        if (part == '*' || part == '**') {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is Directory) nextDirs.add(entity);
          }
        } else {
          final nextDir = Directory(p.join(dir.path, part));
          if (nextDir.existsSync()) nextDirs.add(nextDir);
        }
      }

      currentDirs = nextDirs;
    }

    return currentDirs;
  }

  bool _shouldIgnore(String filePath) {
    final relativePath = p.relative(filePath, from: rootPath);

    for (final pattern in config.effectiveIgnorePatterns) {
      if (_matchesGlob(relativePath, pattern)) return true;
    }

    return false;
  }

  bool _matchesGlob(String path, String pattern) {
    var regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('**/', '.*')
        .replaceAll('**', '.*')
        .replaceAll('*', '[^/]*')
        .replaceAll('?', '.');

    regexPattern = '^$regexPattern\$';

    return RegExp(regexPattern).hasMatch(path);
  }
}
