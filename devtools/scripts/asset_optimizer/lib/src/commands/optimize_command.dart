import 'package:args/command_runner.dart';
import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';
import 'package:asset_optimizer/src/services/asset_optimizer_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to optimize image assets.
class OptimizeCommand() extends Command<int> {
  /// Creates a new [OptimizeCommand].
  this {
    argParser
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Preview changes without optimizing files.',
        negatable: false,
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to YAML config file (default: asset_optimizer.yaml).',
      );
  }

  @override
  String get name => 'optimize';

  @override
  String get description => 'Optimize image assets (SVG, PNG, JPEG).';

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;
    final configPath = argResults!['config'] as String?;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();

      var config = _loadConfig(rootPath, configPath);
      config = config.withDefaults();

      final service = AssetOptimizerService(
        rootPath: rootPath,
        config: config,
        logger: logger,
      );

      // Check for required tools before starting.
      final missingTools = await service.getMissingTools();
      if (missingTools.isNotEmpty) {
        logger.error('Missing required tools:');
        for (final entry in missingTools.entries) {
          logger.error('  ${entry.key}: install with: ${entry.value}');
        }
        return 1;
      }

      // Show active configuration.
      logger.info('Configuration:');
      if (config.svg.enabled) logger.info('  SVG: svgo');
      if (config.png.enabled) {
        logger.info('  PNG: oxipng (level ${config.png.level})');
      }
      if (config.jpeg.enabled) {
        logger.info('  JPEG: jpegoptim (quality ${config.jpeg.quality})');
      }

      final files = service.findAssets();

      if (files.isEmpty) {
        logger.info('No assets found to optimize.');
        return 0;
      }

      logger.info('Found ${files.length} asset file(s)');

      if (dryRun) {
        logger.info('Dry run - files that would be optimized:');
      }

      final summary = await service.optimizeAll(dryRun: dryRun, files: files);

      logger
        ..info('')
        ..info('Summary:')
        ..info('  Files processed: ${summary.results.length}')
        ..info('  Successful: ${summary.successful.length}');

      if (summary.failed.isNotEmpty) {
        logger.info('  Failed: ${summary.failed.length}');
      }

      if (summary.totalSavings > 0) {
        logger.info(
          '  Total savings: ${summary.totalSavingsFormatted} '
          '(${summary.totalReductionPercent.toStringAsFixed(1)}% reduction)',
        );
      }

      return summary.failed.isEmpty ? 0 : 1;
    } on Exception catch (e) {
      logger.error('Failed: $e');
      return 1;
    }
  }

  AssetOptimizerConfig _loadConfig(String rootPath, String? configPath) {
    if (configPath != null) {
      final config = AssetOptimizerConfig.fromYamlFile(
        p.join(rootPath, configPath),
      );
      if (config != null) return config;
    }

    final defaultConfig = AssetOptimizerConfig.fromYamlFile(
      p.join(rootPath, 'asset_optimizer.yaml'),
    );
    if (defaultConfig != null) return defaultConfig;

    return const AssetOptimizerConfig();
  }
}
