import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:coverage_manager/src/services/coverage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run tests with coverage.
class RunCommand() extends Command<int> {
  /// Creates a new [RunCommand].
  this {
    argParser
      ..addOption(
        'concurrency',
        abbr: 'j',
        help: 'Number of packages to test in parallel.',
        defaultsTo: '1',
      )
      ..addOption(
        'package',
        abbr: 'p',
        help: 'Run tests for a specific package only.',
      )
      ..addFlag('fail-fast', help: 'Stop on first failure.', defaultsTo: true);
  }

  @override
  String get name => 'run';

  @override
  String get description => 'Run tests with coverage collection.';

  @override
  Future<int> run() async {
    final concurrency = int.tryParse(argResults!['concurrency'] as String) ?? 1;
    final specificPackage = argResults!['package'] as String?;
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

      return await service.runTests(
        concurrency: concurrency,
        specificPackage: specificPackage,
        failFast: failFast,
      );
    } on Exception catch (e) {
      logger.error('Failed to run tests: $e');
      return 1;
    }
  }
}
