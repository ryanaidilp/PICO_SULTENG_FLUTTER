import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to create a coverage.yaml config template.
class InitCommand() extends Command<int> {
  @override
  String get name => 'init';

  @override
  String get description => 'Create a coverage.yaml config template.';

  @override
  Future<int> run() async {
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final configPath = p.join(rootPath, 'coverage.yaml');
      final configFile = File(configPath);

      if (configFile.existsSync()) {
        logger.warning('coverage.yaml already exists at $configPath');
        return 0;
      }

      await configFile.writeAsString(CoverageConfig.generateDefault());
      logger.success('Created coverage.yaml at $configPath');
      return 0;
    } on Exception catch (e) {
      logger.error('Failed to create coverage.yaml: $e');
      return 1;
    }
  }
}
