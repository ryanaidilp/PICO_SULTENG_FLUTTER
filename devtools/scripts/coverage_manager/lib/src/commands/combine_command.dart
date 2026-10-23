import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:coverage_manager/src/services/coverage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to merge lcov reports from all packages.
class CombineCommand() extends Command<int> {
  /// Creates a new [CombineCommand].
  this {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path for the combined lcov report.',
    );
  }

  @override
  String get name => 'combine';

  @override
  String get description => 'Merge lcov reports from all packages.';

  @override
  Future<int> run() async {
    final outputPath = argResults!['output'] as String?;
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

      return await service.combineReports(outputPath: outputPath);
    } on Exception catch (e) {
      logger.error('Failed to combine reports: $e');
      return 1;
    }
  }
}
