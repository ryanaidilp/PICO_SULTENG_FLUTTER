import 'dart:io';

import 'package:affected/src/models/affected_config.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Service for detecting affected packages based on git changes.
class AffectedService({
  /// The root path of the monorepo.
  required final String rootPath,

  /// Configuration for affected packages.
  required final AffectedConfig config,
  CliLogger? logger,
}) {
  /// Creates an [AffectedService].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  /// Get list of changed files from git diff.
  ///
  /// `--relative` keeps paths relative to [rootPath] and drops files outside
  /// it, so a workspace nested in a larger git repo still maps files to its
  /// packages.
  Future<List<String>> getChangedFiles(String baseBranch) async {
    final result = await ShellRunner.run(
      'git diff --name-only --relative $baseBranch...HEAD',
      workingDirectory: rootPath,
    );

    if (result.exitCode != 0) {
      // Try without the triple dot (for commits on same branch).
      final fallbackResult = await ShellRunner.run(
        'git diff --name-only --relative $baseBranch',
        workingDirectory: rootPath,
      );

      if (fallbackResult.exitCode != 0) {
        throw Exception(
          'Failed to get changed files: ${fallbackResult.stderr}',
        );
      }

      return _parseGitOutput(fallbackResult.stdout.toString());
    }

    return _parseGitOutput(result.stdout.toString());
  }

  List<String> _parseGitOutput(String output) => output
      .split('\n')
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();

  /// Find the package that contains a file.
  String? findPackageForFile(String filePath) {
    var dir = p.dirname(filePath);

    while (dir != '.' && dir.isNotEmpty) {
      final pubspecPath = p.join(rootPath, dir, 'pubspec.yaml');
      if (File(pubspecPath).existsSync()) {
        return dir;
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    return null;
  }

  /// Get set of directly affected packages from changed files.
  Set<String> getAffectedPackages(List<String> changedFiles) {
    final packages = <String>{};

    for (final file in changedFiles) {
      if (_shouldIgnore(file)) continue;

      final packagePath = findPackageForFile(file);
      if (packagePath != null) {
        packages.add(packagePath);
      }
    }

    // Add always-include packages.
    for (final pkg in config.alwaysInclude) {
      final pubspecPath = p.join(rootPath, pkg, 'pubspec.yaml');
      if (File(pubspecPath).existsSync()) {
        packages.add(pkg);
      }
    }

    return packages;
  }

  /// Get affected packages including transitive dependents.
  ///
  /// If package A changed and package B depends on A, B is affected too.
  Set<String> getAffectedWithDependents(List<String> changedFiles) {
    final directlyAffected = getAffectedPackages(changedFiles);
    final allPackages = PackageScanner.scan(rootPath);

    // Build a map of package name -> package path for affected packages.
    final affectedNames = <String>{};
    for (final affected in directlyAffected) {
      final pubspecFile = File(p.join(rootPath, affected, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        for (final pkg in allPackages) {
          if (pkg.path == p.join(rootPath, affected) ||
              pkg.path.endsWith('/$affected')) {
            affectedNames.add(pkg.name);
          }
        }
      }
    }

    final result = Set<String>.from(directlyAffected);

    // Find transitive dependents.
    var changed = true;
    while (changed) {
      changed = false;
      for (final pkg in allPackages) {
        final relativePath = p.relative(pkg.path, from: rootPath);
        if (result.contains(relativePath)) continue;

        final allDeps = [...pkg.dependencies, ...pkg.devDependencies];
        if (allDeps.any(affectedNames.contains)) {
          result.add(relativePath);
          affectedNames.add(pkg.name);
          changed = true;
        }
      }
    }

    return result;
  }

  bool _shouldIgnore(String filePath) {
    for (final pattern in config.ignore) {
      if (_matchesGlob(filePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesGlob(String filePath, String pattern) {
    final regexPattern = pattern
        .replaceAll('.', r'\.')
        // A NUL placeholder: a `` one is a mustache tag in the brick
        // and rendered to an empty string.
        .replaceAll('**', '\u0000')
        .replaceAll('*', '[^/]*')
        .replaceAll('\u0000', '.*');

    final regex = RegExp('^$regexPattern');
    return regex.hasMatch(filePath);
  }

  /// Run a command in each affected package.
  Future<int> runInPackages({
    required List<String> packages,
    required String commandString,
    bool failFast = false,
    Set<int> okExitCodes = const {0},
    String? requiredDir,
  }) async {
    final sorted = packages.toList()..sort();
    var hasFailures = false;

    for (final packagePath in sorted) {
      final fullPath = p.join(rootPath, packagePath);
      // A dependent without lib/ or test/ has nothing to analyze or test;
      // `flutter test` would fail with "Test directory not found".
      if (requiredDir != null &&
          !Directory(p.join(fullPath, requiredDir)).existsSync()) {
        _logger.info('[$packagePath] Skipped: no $requiredDir/');
        continue;
      }
      _logger.progress('[$packagePath] $commandString');

      final result = await ShellRunner.run(
        commandString,
        workingDirectory: fullPath,
      );

      if (!okExitCodes.contains(result.exitCode)) {
        hasFailures = true;
        _logger.error('[$packagePath] Failed (exit code: ${result.exitCode})');
        final stderr = result.stderr.toString().trim();
        if (stderr.isNotEmpty) _logger.error(stderr);

        if (failFast) return 1;
      } else {
        _logger.success('[$packagePath] Passed');
      }
    }

    return hasFailures ? 1 : 0;
  }
}
