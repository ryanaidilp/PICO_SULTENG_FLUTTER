import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:coverage_manager/src/services/coverage_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to verify coverage against configured thresholds.
class CheckCommand() extends Command<int> {
  @override
  String get name => 'check';

  @override
  String get description => 'Verify coverage against configured thresholds.';

  @override
  Future<int> run() async {
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

      return await service.checkThresholds();
    } on Exception catch (e) {
      logger.error('Failed to check thresholds: $e');
      return 1;
    }
  }
}
