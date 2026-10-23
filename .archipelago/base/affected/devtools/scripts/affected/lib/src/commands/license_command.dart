import 'dart:convert';
import 'dart:io';

import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Default SPDX license identifiers that are considered allowable.
const _defaultAllowlist = [
  'MIT',
  'Apache-2.0',
  'BSD-3-Clause',
  'BSD-2-Clause',
  'ISC',
  'Zlib',
];

/// Command to audit transitive dependency licenses for affected packages.
///
/// Uses `dart pub deps --json` to enumerate transitive dependencies, then
/// reads each dep's LICENSE file from the Pub cache. Exits non-zero if any
/// dependency carries a license not in the allowlist.
class LicenseCommand() extends Command<int> {
  /// Creates a new [LicenseCommand].
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addMultiOption(
        'allow',
        help: 'Additional SPDX license identifiers to allow (repeatable).',
        valueHelp: 'LICENSE',
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package with a disallowed license.',
        negatable: false,
      );
  }

  @override
  String get name => 'license';

  @override
  String get description =>
      'Audit transitive dependency licenses for affected packages. '
      'Fails if any dependency has a license not in the allowlist.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final extraAllowed = argResults!['allow'] as List<String>;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    final allowlist = {..._defaultAllowlist, ...extraAllowed};

    logger
      ..info('License allowlist: ${allowlist.join(', ')}')
      ..info('');

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

      logger
        ..info('Comparing HEAD with $baseBranch...')
        ..info('Found ${affectedPackages.length} affected package(s)')
        ..info('');

      var hasViolations = false;

      for (final packagePath in affectedPackages.toList()..sort()) {
        final fullPath = p.join(rootPath, packagePath);
        logger.progress('[$packagePath] Auditing licenses...');

        final deps = await _collectDeps(fullPath);
        if (deps == null) {
          logger.error('[$packagePath] Failed to run dart pub deps --json');
          if (failFast) return 1;
          hasViolations = true;
          continue;
        }

        final violations = <String>[];
        final reported = <String>{};

        for (final dep in deps) {
          final name = dep['name'] as String? ?? '';
          final version = dep['version'] as String? ?? '';
          if (name.isEmpty || reported.contains('$name@$version')) continue;
          reported.add('$name@$version');

          final license = await _detectLicense(name, version);
          final spdx = _normalizeSpdx(license);

          if (!_isAllowed(spdx, allowlist)) {
            violations.add('  $name $version — $spdx');
          } else {
            logger.info('  $name $version — $spdx');
          }
        }

        if (violations.isNotEmpty) {
          hasViolations = true;
          logger.error(
            '[$packagePath] ${violations.length} disallowed license(s):',
          );
          violations.forEach(logger.error);
          if (failFast) return 1;
        } else {
          logger.success('[$packagePath] All licenses allowed.');
        }
      }

      return hasViolations ? 1 : 0;
    } on Exception catch (e) {
      logger.error('Failed to run license audit: $e');
      return 1;
    }
  }

  /// Runs `dart pub deps --json` in [packagePath] and returns a flat list of
  /// all transitive dependency maps (name + version).
  Future<List<Map<String, dynamic>>?> _collectDeps(String packagePath) async {
    final result = await ShellRunner.run(
      'dart pub deps --json',
      workingDirectory: packagePath,
    );

    if (result.exitCode != 0) return null;

    try {
      final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final packages = json['packages'] as List<dynamic>? ?? [];
      return packages.cast<Map<String, dynamic>>();
    } on Exception {
      return null;
    }
  }

  /// Attempts to detect the license for a package by reading its LICENSE file
  /// from the Pub cache. Falls back to 'UNKNOWN' if not found.
  Future<String> _detectLicense(String name, String version) async {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (home.isEmpty) return 'UNKNOWN';

    // Pub cache layout: ~/.pub-cache/hosted/pub.dev/<name>-<version>/LICENSE
    final cacheDir = p.join(home, '.pub-cache', 'hosted', 'pub.dev');
    final pkgDir = p.join(cacheDir, '$name-$version');

    for (final candidate in [
      'LICENSE',
      'LICENSE.md',
      'LICENSE.txt',
      'LICENCE',
    ]) {
      final file = File(p.join(pkgDir, candidate));
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }

    return 'UNKNOWN';
  }

  /// Normalises raw license text to a known SPDX identifier when possible.
  String _normalizeSpdx(String raw) {
    if (raw == 'UNKNOWN') return 'UNKNOWN';

    final upper = raw.toUpperCase();

    if (upper.contains('MIT LICENSE') || upper.startsWith('MIT')) return 'MIT';
    if (upper.contains('APACHE LICENSE') && upper.contains('2.0')) {
      return 'Apache-2.0';
    }
    if (upper.contains('BSD 3-CLAUSE') ||
        upper.contains('BSD THREE CLAUSE') ||
        (upper.contains('BSD') && upper.contains('3'))) {
      return 'BSD-3-Clause';
    }
    if (upper.contains('BSD 2-CLAUSE') ||
        upper.contains('BSD TWO CLAUSE') ||
        (upper.contains('BSD') && upper.contains('2'))) {
      return 'BSD-2-Clause';
    }
    if (upper.contains('ISC LICENSE') || upper.startsWith('ISC')) return 'ISC';
    if (upper.contains('ZLIB') || upper.contains('ZLIB/LIBPNG')) return 'Zlib';

    // Return first line as a best-effort label.
    return raw.split('\n').first.trim();
  }

  bool _isAllowed(String spdx, Set<String> allowlist) {
    if (spdx == 'UNKNOWN') return false;
    return allowlist.any(
      (allowed) => spdx.toLowerCase() == allowed.toLowerCase(),
    );
  }
}
