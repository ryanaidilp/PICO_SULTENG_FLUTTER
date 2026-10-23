import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:size_guard/src/models/size_guard_config.dart';
import 'package:size_guard/src/services/size_guard_service.dart';

/// Command to check for files exceeding size thresholds.
class CheckCommand() extends Command<int> {
  /// Creates a new [CheckCommand].
  this {
    argParser
      ..addOption(
        'threshold',
        abbr: 't',
        help: 'Size threshold (e.g., 500KB, 1MB). Default: 500KB.',
        defaultsTo: '500KB',
      )
      ..addMultiOption(
        'extension',
        abbr: 'e',
        help: 'File extensions to check.',
      )
      ..addMultiOption('ignore', abbr: 'i', help: 'Paths to ignore.')
      ..addOption('config', abbr: 'c', help: 'Path to YAML config file.')
      ..addFlag(
        'stats',
        abbr: 's',
        help: 'Show detailed statistics.',
        negatable: false,
      )
      ..addFlag(
        'changed-only',
        help: 'Check only files changed in this PR/branch vs the base branch.',
        negatable: false,
      )
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch to diff against. Auto-detected from CI env if omitted.',
      );
  }

  @override
  String get name => 'check';

  @override
  String get description => 'Check for files exceeding the size threshold.';

  @override
  Future<int> run() async {
    final thresholdStr = argResults!['threshold'] as String;
    final thresholdExplicit = argResults!.wasParsed('threshold');
    final customExtensions = argResults!['extension'] as List<String>;
    final customIgnorePaths = argResults!['ignore'] as List<String>;
    final configPath = argResults!['config'] as String?;
    final showStats = argResults!['stats'] as bool;
    final changedOnly = argResults!['changed-only'] as bool;
    final baseBranch = argResults!['base'] as String?;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();

      var config = _loadConfig(rootPath, configPath);
      config = _applyOverrides(
        config,
        thresholdStr: thresholdStr,
        thresholdExplicit: thresholdExplicit,
        customExtensions: customExtensions,
        customIgnorePaths: customIgnorePaths,
      );

      logger
        ..info('Configuration:')
        ..info('  Threshold: ${config.thresholdFormatted}')
        ..info('  Extensions: ${config.extensions.length} types')
        ..info('  Ignore paths: ${config.ignorePaths.length} paths');

      final service = SizeGuardService(rootPath: rootPath, config: config);

      if (changedOnly) {
        final changedFiles = await GitChanges.getChangedFiles(
          baseBranch: baseBranch,
          rootPath: rootPath,
        );
        logger.info('Checking ${changedFiles.length} changed file(s)...');

        final violations = service.scanChanged(changedFiles);

        if (violations.isNotEmpty) {
          logger.error(
            'Found ${violations.length} changed file(s) exceeding '
            '${config.thresholdFormatted}:',
          );
          _printViolations(logger, violations);
          return 1;
        }
        logger.success(
          'No changed files exceed the ${config.thresholdFormatted} limit.',
        );
        return 0;
      }

      if (showStats) {
        final stats = service.scanWithStats();

        logger.info(
          'Scanned ${stats.totalFilesScanned} files '
          '(${stats.totalBytesFormatted})',
        );

        if (stats.hasViolations) {
          logger.error(
            'Found ${stats.violationCount} file(s) exceeding '
            '${config.thresholdFormatted}:',
          );
          _printViolations(logger, stats.violations);
          logger.info(
            'Total violation size: ${stats.totalViolationBytesFormatted}',
          );
          return 1;
        }
        logger.success(
          'All ${stats.totalFilesScanned} files are within the '
          '${config.thresholdFormatted} limit.',
        );
        return 0;
      }

      final violations = service.scan();

      if (violations.isNotEmpty) {
        logger.error(
          'Found ${violations.length} file(s) exceeding '
          '${config.thresholdFormatted}:',
        );
        _printViolations(logger, violations);
        return 1;
      }
      logger.success('No files exceed the ${config.thresholdFormatted} limit.');
      return 0;
    } on Exception catch (e) {
      logger.error('Failed: $e');
      return 1;
    }
  }

  SizeGuardConfig _loadConfig(String rootPath, String? configPath) {
    if (configPath != null) {
      final config = SizeGuardConfig.fromYamlFile(p.join(rootPath, configPath));
      if (config != null) return config;
    }

    final defaultConfig = SizeGuardConfig.fromYamlFile(
      p.join(rootPath, 'size_guard.yaml'),
    );
    if (defaultConfig != null) return defaultConfig;

    return const SizeGuardConfig();
  }

  SizeGuardConfig _applyOverrides(
    SizeGuardConfig config, {
    required String thresholdStr,
    required bool thresholdExplicit,
    required List<String> customExtensions,
    required List<String> customIgnorePaths,
  }) {
    final threshold = thresholdExplicit
        ? SizeGuardConfig.parseThreshold(thresholdStr)
        : null;

    final extensions = customExtensions.isNotEmpty
        ? {...SizeGuardConfig.defaultExtensions, ...customExtensions}
        : config.extensions;

    final ignorePaths = customIgnorePaths.isNotEmpty
        ? {...SizeGuardConfig.defaultIgnorePaths, ...customIgnorePaths}
        : config.ignorePaths;

    return SizeGuardConfig(
      thresholdBytes: threshold ?? config.thresholdBytes,
      extensions: extensions,
      ignorePaths: ignorePaths,
      ignorePatterns: config.ignorePatterns,
    );
  }

  void _printViolations(CliLogger logger, List<SizeViolation> violations) {
    for (final violation in violations) {
      logger
        ..info('  ${violation.path}')
        ..info(
          '    Size: ${violation.sizeFormatted} '
          '(+${violation.excessFormatted} over limit)',
        );
    }
  }
}
