import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:coverage_manager/src/services/coverage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run tests, combine reports, and check thresholds all-in-one.
class FullCommand() extends Command<int> {
  /// Creates a new [FullCommand].
  this {
    argParser
      ..addOption(
        'concurrency',
        abbr: 'j',
        help: 'Number of packages to test in parallel.',
        defaultsTo: '1',
      )
      ..addFlag('fail-fast', help: 'Stop on first failure.', defaultsTo: true);
  }

  @override
  String get name => 'full';

  @override
  String get description => 'Run tests, combine reports, and check thresholds.';

  @override
  Future<int> run() async {
    final concurrency = int.tryParse(argResults!['concurrency'] as String) ?? 1;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final configPath = p.join(rootPath, 'coverage.yaml');
      final config =
          CoverageConfig.fromFile(configPath) ?? const CoverageConfig();

      final service = CoverageService(
        rootPath: rootPath,
        config: config,
        logger: logger,
      );

      // Step 1: Run tests.
      logger.info('Step 1/3: Running tests with coverage...');
      final testResult = await service.runTests(
        concurrency: concurrency,
        failFast: failFast,
      );

      if (testResult != 0) {
        logger.error('Tests failed. Stopping pipeline.');
        return testResult;
      }

      // Step 2: Combine reports.
      logger.info('Step 2/3: Combining coverage reports...');
      final combineResult = await service.combineReports();

      if (combineResult != 0) {
        logger.error('Failed to combine coverage reports.');
        return combineResult;
      }

      // Step 3: Check thresholds.
      logger.info('Step 3/3: Checking coverage thresholds...');
      return await service.checkThresholds();
    } on Exception catch (e) {
      logger.error('Coverage pipeline failed: $e');
      return 1;
    }
  }
}
