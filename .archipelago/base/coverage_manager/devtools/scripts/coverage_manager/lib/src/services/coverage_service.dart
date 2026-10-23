import 'dart:io';

import 'package:coverage_manager/src/models/coverage_config.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Service for running tests with coverage and managing lcov reports.
class CoverageService({
  /// Root path of the monorepo.
  required final String rootPath,

  /// Coverage configuration.
  required final CoverageConfig config,
  CliLogger? logger,
}) {
  /// Creates a new [CoverageService].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  /// Runs tests with coverage for the given packages.
  Future<int> runTests({
    int concurrency = 1,
    String? specificPackage,
    bool failFast = false,
  }) async {
    final packages = PackageScanner.scan(rootPath);
    final testablePackages = packages.where((pkg) {
      if (specificPackage != null) return pkg.name == specificPackage;
      if (!pkg.hasTests) return false;

      final effectiveConfig = config.getEffectiveConfig(pkg.name);
      return !effectiveConfig.skip;
    }).toList();

    if (testablePackages.isEmpty) {
      _logger.info('No testable packages found.');
      return 0;
    }

    _logger.info('Running tests for ${testablePackages.length} package(s)...');

    var hasFailures = false;

    for (final pkg in testablePackages) {
      _logger.progress('[${pkg.name}] Running tests...');

      final result = await ShellRunner.run(
        'flutter test --coverage',
        workingDirectory: pkg.path,
      );

      if (result.exitCode != 0) {
        hasFailures = true;
        _logger.error('[${pkg.name}] Tests failed');
        if (failFast) return 1;
      } else {
        _logger.success('[${pkg.name}] Tests passed');
      }
    }

    return hasFailures ? 1 : 0;
  }

  /// Combines lcov reports from all packages into a single report.
  Future<int> combineReports({String? outputPath}) async {
    final output = outputPath ?? p.join(rootPath, 'coverage', 'lcov.info');
    final packages = PackageScanner.scan(rootPath);
    final buffer = StringBuffer();
    var count = 0;

    for (final pkg in packages) {
      final lcovPath = p.join(pkg.path, 'coverage', 'lcov.info');
      final lcovFile = File(lcovPath);

      if (!lcovFile.existsSync()) continue;

      final content = filterLcov(
        lcovFile.readAsStringSync(),
        config.getEffectiveConfig(pkg.name).allExclusions,
        pkg.path,
      );
      if (content.trim().isEmpty) continue;

      // Rewrite paths to be relative to monorepo root.
      final relativePkgPath = p.relative(pkg.path, from: rootPath);
      final rewritten = content.replaceAllMapped(
        RegExp(r'^SF:(.+)$', multiLine: true),
        (match) {
          final filePath = match.group(1)!;
          if (p.isAbsolute(filePath)) {
            final relative = p.relative(filePath, from: pkg.path);
            return 'SF:$relativePkgPath/$relative';
          }
          return 'SF:$relativePkgPath/$filePath';
        },
      );

      buffer.write(rewritten);
      if (!rewritten.endsWith('\n')) buffer.writeln();
      count++;
    }

    if (count == 0) {
      _logger.warning('No lcov reports found to combine.');
      return 1;
    }

    final outputFile = File(output);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(buffer.toString());

    _logger.success('Combined $count lcov report(s) into $output');
    return 0;
  }

  /// Checks coverage against configured thresholds.
  ///
  /// Files matching `exclude_patterns`/`exclude_files` are dropped first.
  /// Branch and function thresholds apply only when the report has that
  /// data: `flutter test --coverage` writes neither unless asked
  /// (`--branch-coverage`).
  Future<int> checkThresholds() async {
    final packages = PackageScanner.scan(rootPath);
    var hasFailures = false;

    for (final pkg in packages) {
      final effectiveConfig = config.getEffectiveConfig(pkg.name);
      if (effectiveConfig.skip) continue;

      final lcovPath = p.join(pkg.path, 'coverage', 'lcov.info');
      final lcovFile = File(lcovPath);

      if (!lcovFile.existsSync()) continue;

      final result = parseLcov(
        filterLcov(
          lcovFile.readAsStringSync(),
          effectiveConfig.allExclusions,
          pkg.path,
        ),
      );

      final checks = [
        ('Line', result.lineCoverage, effectiveConfig.minLineThreshold, true),
        (
          'Branch',
          result.branchCoverage,
          effectiveConfig.minBranchThreshold,
          result.branchesTotal > 0,
        ),
        (
          'Function',
          result.functionCoverage,
          effectiveConfig.minFunctionThreshold,
          result.functionsTotal > 0,
        ),
      ];

      for (final (kind, coverage, threshold, measured) in checks) {
        if (!measured) continue;
        final summary =
            '[${pkg.name}] $kind coverage ${coverage.toStringAsFixed(1)}%';
        if (coverage < threshold) {
          _logger.error('$summary below threshold $threshold%');
          hasFailures = true;
        } else {
          _logger.success('$summary (threshold: $threshold%)');
        }
      }
    }

    return hasFailures ? 1 : 0;
  }
}

/// Drops lcov records whose `SF:` file matches one of [exclusions].
///
/// A pattern without `/` matches the file name anywhere (`*.g.dart`); a
/// pattern with `/` matches the path relative to [packagePath]
/// (`lib/main_*.dart`, `**/generated/**`).
String filterLcov(String content, List<String> exclusions, String packagePath) {
  if (exclusions.isEmpty) return content;
  final globs = [
    for (final glob in exclusions) (glob.contains('/'), _globToRegExp(glob)),
  ];

  return content
      .split(RegExp(r'^end_of_record\n?', multiLine: true))
      .where((record) {
        final source = RegExp(
          r'^SF:(.+)$',
          multiLine: true,
        ).firstMatch(record)?.group(1);
        if (source == null) return false;
        final path = p.posix.normalize(
          p.isAbsolute(source) ? p.relative(source, from: packagePath) : source,
        );
        return !globs.any(
          (g) => g.$2.hasMatch(g.$1 ? path : p.posix.basename(path)),
        );
      })
      .map((record) => '${record}end_of_record\n')
      .join();
}

/// Sums the line, branch and function totals of an lcov report.
///
/// `flutter test --branch-coverage` writes `BRDA` records but no `BRF`/`BRH`
/// summary, so branches (and functions, from `FN`/`FNDA`) are counted from
/// the detail records when the summary is missing.
CoverageResult parseLcov(String content) {
  final totals = <String, int>{};
  void add(String key, int value) => totals[key] = (totals[key] ?? 0) + value;
  for (final line in content.split('\n')) {
    final colon = line.indexOf(':');
    if (colon == -1) continue;
    final key = line.substring(0, colon);
    final value = line.substring(colon + 1);
    if (const {'LH', 'LF', 'BRH', 'BRF', 'FNH', 'FNF'}.contains(key)) {
      add(key, int.tryParse(value) ?? 0);
    } else if (key == 'BRDA') {
      add('brda', 1);
      final taken = value.split(',').last;
      if (taken != '-' && taken != '0') add('brdaHit', 1);
    } else if (key == 'FN') {
      add('fn', 1);
    } else if (key == 'FNDA' && !value.startsWith('0,')) {
      add('fnHit', 1);
    }
  }

  return CoverageResult(
    packageName: '',
    packagePath: '',
    linesCovered: totals['LH'] ?? 0,
    linesTotal: totals['LF'] ?? 0,
    branchesCovered: totals['BRH'] ?? totals['brdaHit'] ?? 0,
    branchesTotal: totals['BRF'] ?? totals['brda'] ?? 0,
    functionsCovered: totals['FNH'] ?? totals['fnHit'] ?? 0,
    functionsTotal: totals['FNF'] ?? totals['fn'] ?? 0,
  );
}

RegExp _globToRegExp(String glob) {
  final out = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (glob.startsWith('**/', i)) {
      out.write('(?:.*/)?');
      i += 2;
    } else if (glob.startsWith('**', i)) {
      out.write('.*');
      i++;
    } else if (c == '*') {
      out.write('[^/]*');
    } else if (c == '?') {
      out.write('[^/]');
    } else {
      out.write(RegExp.escape(c));
    }
  }
  return RegExp('$out\$');
}
