import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:permission_guard/src/services/android_permission_service.dart';
import 'package:permission_guard/src/services/ios_permission_service.dart';
import 'package:permission_guard/src/services/permission_guard_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

class UpdateBaselineCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'platform',
        allowed: ['android', 'ios'],
        mandatory: true,
        help: 'Platform to update baseline for.',
      )
      ..addOption(
        'artifact',
        mandatory: true,
        help: 'Path to the compiled APK or IPA.',
      )
      ..addOption(
        'output',
        help:
            'Output path for the baseline file. Defaults to the '
            'android_baseline_path/ios_baseline_path in .permissionguard.yaml '
            'for the given platform.',
      );
  }

  @override
  String get name => 'update-baseline';

  @override
  String get description =>
      'Update the permission baseline from a compiled artifact.';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    final rootPath = MonorepoFinder.requireRoot();
    final config = PermissionGuardService.loadConfig(rootPath);
    final platform = argResults!['platform'] as String;
    final artifactPath = argResults!['artifact'] as String;
    final outputRelPath =
        (argResults!['output'] as String?) ??
        (platform == 'android'
            ? config.androidBaselinePath
            : config.iosBaselinePath);
    final outputPath = p.join(rootPath, outputRelPath);

    logger.info('Extracting permissions from $platform artifact...');

    List<String> permissions;
    try {
      if (platform == 'android') {
        permissions = await const AndroidPermissionService().extractPermissions(
          artifactPath,
        );
      } else {
        permissions = await const IosPermissionService().extractPermissions(
          artifactPath,
        );
      }
    } catch (e) {
      logger.error('Failed to extract permissions: $e');
      return 1;
    }

    final guardService = PermissionGuardService(rootPath: rootPath);
    await guardService.saveBaseline(permissions, outputPath);

    logger.success(
      'Baseline updated with ${permissions.length} permission(s) at $outputRelPath.',
    );
    return 0;
  }
}
