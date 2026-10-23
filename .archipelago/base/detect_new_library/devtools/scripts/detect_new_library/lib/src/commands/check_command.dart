import 'package:args/command_runner.dart';
import 'package:detect_new_library/src/services/detect_new_library_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

class CheckCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch to diff against (auto-detected from CI env if omitted).',
      )
      ..addFlag(
        'fail',
        help: 'Exit with code 1 if new libraries are detected (overrides config).',
        negatable: false,
      );
  }

  @override
  String get name => 'check';

  @override
  String get description =>
      'Report newly added direct dependencies across the monorepo.';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final rootPath = MonorepoFinder.requireRoot();
    final config = DetectNewLibraryService.loadConfig(rootPath);
    final service = DetectNewLibraryService(rootPath: rootPath, config: config);
    final baseBranch = argResults?['base'] as String?;
    final failFlag = argResults?['fail'] as bool? ?? false;

    logger.info('Scanning for new direct dependencies...');
    final findings = await service.findNewDependencies(baseBranch: baseBranch);

    if (findings.isEmpty) {
      logger.success('No new direct dependencies detected.');
      return 0;
    }

    logger.info('New direct dependencies detected:');
    for (final f in findings) {
      logger.info('\n  ${f.pubspecPath}:');
      for (final pkg in f.addedPackages) {
        logger.info('    + $pkg');
      }
    }
    logger.info(
      '\nReview new packages for app size, licensing, and compatibility impact.',
    );

    return (failFlag || config.failOnNew) ? 1 : 0;
  }
}
