import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:permission_guard/src/services/android_permission_service.dart';
import 'package:permission_guard/src/services/permission_guard_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

class AndroidCommand() extends Command<int> {
  this {
    argParser
      ..addOption('apk', mandatory: true, help: 'Path to the compiled APK.')
      ..addOption(
        'baseline',
        help:
            'Path to the baseline file. Defaults to the '
            'android_baseline_path in .permissionguard.yaml.',
      );
  }

  @override
  String get name => 'android';

  @override
  String get description => 'Check Android APK permissions against baseline.';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final rootPath = MonorepoFinder.requireRoot();
    final config = PermissionGuardService.loadConfig(rootPath);
    final apkPath = argResults!['apk'] as String;
    final baselineRelPath =
        (argResults!['baseline'] as String?) ?? config.androidBaselinePath;
    final baselinePath = p.join(rootPath, baselineRelPath);

    logger.info('Extracting permissions from APK...');
    const androidService = AndroidPermissionService();
    final List<String> permissions;
    try {
      permissions = await androidService.extractPermissions(apkPath);
    } catch (e) {
      logger.error('Failed to extract permissions: $e');
      return 1;
    }

    final guardService = PermissionGuardService(rootPath: rootPath);
    final baseline = await guardService.loadBaseline(baselinePath);
    final diff = guardService.diff(
      current: permissions.toSet(),
      baseline: baseline.toSet(),
    );

    if (diff.added.isEmpty && diff.removed.isEmpty) {
      logger.success('No permission changes detected.');
      return 0;
    }

    if (diff.added.isNotEmpty) {
      logger.error('New permissions detected:');
      for (final p in diff.added) {
        logger.error('  + $p');
      }
    }

    if (diff.removed.isNotEmpty) {
      if (config.warnOnRemoved) {
        logger.error('\nPermissions removed (${diff.removed.length}):');
      } else {
        logger.info('\nPermissions removed (${diff.removed.length}):');
      }
      for (final perm in diff.removed) {
        logger.info('  - $perm');
      }
    }

    if (diff.added.isNotEmpty) {
      logger.error(
        'Run `permission-guard update-baseline --platform android --artifact $apkPath` to update the baseline.',
      );
      return (diff.added.isNotEmpty && config.failOnNew) ? 1 : 0;
    }

    return 0;
  }
}
