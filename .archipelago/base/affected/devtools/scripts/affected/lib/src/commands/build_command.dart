import 'dart:io';

import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

/// Command to run flutter build (or dart compile) on affected app packages.
///
/// Only packages that contain a `flutter:` section in pubspec.yaml AND a
/// `lib/main.dart` entry point are considered app packages. Pure library
/// packages are skipped.
class BuildCommand() extends Command<int> {
  /// Creates a new [BuildCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: 'Build platform target.',
        allowed: ['apk', 'aab', 'ios', 'ipa'],
        defaultsTo: 'apk',
        allowedHelp: {
          'apk': 'Android APK',
          'aab': 'Android App Bundle',
          'ios': 'iOS app (requires macOS + Xcode)',
          'ipa': 'iOS IPA archive (requires macOS + Xcode)',
        },
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package failure.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'build';

  @override
  String get description =>
      'Run flutter build on affected app packages only. '
      'Library-only packages are skipped.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final platform = argResults!['platform'] as String;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final configPath = p.join(rootPath, 'affected.yaml');
      final config =
          AffectedConfig.fromYamlFile(configPath)?.withDefaults() ??
          const AffectedConfig().withDefaults();

      final service = AffectedService(rootPath: rootPath, config: config);
      final changedFiles = await service.getChangedFiles(baseBranch);

      if (changedFiles.isEmpty) {
        logger.info('No changes detected compared to $baseBranch.');
        return 0;
      }

      final affectedPackages = service.getAffectedWithDependents(changedFiles);

      if (affectedPackages.isEmpty) {
        logger.info('No packages affected by the changes.');
        return 0;
      }

      // Filter to app packages only.
      final appPackages =
          affectedPackages.where((pkg) => _isAppPackage(rootPath, pkg)).toList()
            ..sort();

      if (appPackages.isEmpty) {
        logger.info(
          'No app packages affected '
          '(${affectedPackages.length} library package(s) skipped).',
        );
        return 0;
      }

      final command = _buildCommand(platform);

      logger
        ..info('Comparing HEAD with $baseBranch...')
        ..info(
          'Found ${appPackages.length} app package(s) '
          '(${affectedPackages.length - appPackages.length} library '
          'package(s) skipped)',
        )
        ..info('Running: $command');

      return await service.runInPackages(
        packages: appPackages,
        commandString: command,
        failFast: failFast,
      );
    } on Exception catch (e) {
      logger.error('Failed to run build: $e');
      return 1;
    }
  }

  /// Returns true if the package is a Flutter app (has a `flutter:` block in
  /// pubspec.yaml AND contains `lib/main.dart`).
  bool _isAppPackage(String rootPath, String packagePath) {
    final fullPath = p.join(rootPath, packagePath);

    // Must have lib/main.dart.
    final mainDart = File(p.join(fullPath, 'lib', 'main.dart'));
    if (!mainDart.existsSync()) return false;

    // Must have a flutter: block in pubspec.yaml.
    final pubspecFile = File(p.join(fullPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;

    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return false;
      return yaml.containsKey('flutter');
    } on Exception {
      return false;
    }
  }

  String _buildCommand(String platform) {
    switch (platform) {
      case 'aab':
        return 'flutter build appbundle --release';
      case 'ios':
        return 'flutter build ios --release --no-codesign';
      case 'ipa':
        return 'flutter build ipa --release';
      case 'apk':
      default:
        return 'flutter build apk --release';
    }
  }
}
