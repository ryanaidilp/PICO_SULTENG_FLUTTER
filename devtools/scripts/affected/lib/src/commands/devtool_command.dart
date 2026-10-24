import 'dart:io';

import 'package:affected/src/models/affected_config.dart';
import 'package:affected/src/services/affected_service.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

// ---------------------------------------------------------------------------
// Parent command
// ---------------------------------------------------------------------------

/// Parent command that wires existing devtools into the affected mechanism.
class DevtoolCommand() extends Command<int> {
  /// Creates a new [DevtoolCommand].
  this {
    addSubcommand(_SizeGuardSubCommand());
    addSubcommand(_DependencyGraphSubCommand());
    addSubcommand(_CoverageSubCommand());
  }

  @override
  String get name => 'devtool';

  @override
  String get description =>
      'Run workspace devtools scoped to affected packages '
      '(size-guard, dependency-graph, coverage).';
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Future<Set<String>?> _resolveAffected(
  String baseBranch,
  CliLogger logger,
) async {
  final rootPath = MonorepoFinder.requireRoot();
  final configPath = p.join(rootPath, 'affected.yaml');
  final config =
      AffectedConfig.fromYamlFile(configPath)?.withDefaults() ??
      const AffectedConfig().withDefaults();

  final service = AffectedService(rootPath: rootPath, config: config);
  final changedFiles = await service.getChangedFiles(baseBranch);

  if (changedFiles.isEmpty) {
    logger.info('No changes detected compared to $baseBranch.');
    return const {};
  }

  return service.getAffectedWithDependents(changedFiles);
}

/// Resolves affected package names (not paths) for use as `--package` args.
Future<List<String>?> _resolveAffectedNames(
  String baseBranch,
  CliLogger logger,
) async {
  final rootPath = MonorepoFinder.requireRoot();
  final affectedPaths = await _resolveAffected(baseBranch, logger);
  if (affectedPaths == null) return null;
  if (affectedPaths.isEmpty) return const [];

  final allPackages = PackageScanner.scan(rootPath);
  final names = <String>[];

  for (final pkgPath in affectedPaths) {
    final fullPath = p.join(rootPath, pkgPath);
    for (final pkg in allPackages) {
      if (pkg.path == fullPath || pkg.path.endsWith('/$pkgPath')) {
        names.add(pkg.name);
        break;
      }
    }
  }

  return names;
}

// ---------------------------------------------------------------------------
// size-guard sub-command
// ---------------------------------------------------------------------------

class _SizeGuardSubCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addFlag(
        'changed-only',
        help: 'Check only files changed in this PR/branch (default: true).',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'size-guard';

  @override
  String get description =>
      'Run size_guard check scoped to affected changes. '
      'Delegates to `dart run size_guard check --changed-only`.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final changedOnly = argResults!['changed-only'] as bool;
    final logger = CliLogger();

    final affectedPaths = await _resolveAffected(baseBranch, logger);
    if (affectedPaths == null) return 1;

    if (affectedPaths.isEmpty) {
      logger.info('No packages affected by the changes.');
      return 0;
    }

    logger
      ..info('Comparing HEAD with $baseBranch...')
      ..info('Found ${affectedPaths.length} affected package(s)')
      ..info('Running: dart run size_guard check');

    final rootPath = MonorepoFinder.requireRoot();

    final args = [
      'run',
      'size_guard',
      'check',
      if (changedOnly) '--changed-only',
      if (changedOnly) '--base',
      if (changedOnly) baseBranch,
    ];

    final result = await Process.run(
      'dart',
      args,
      workingDirectory: rootPath,
      runInShell: true,
    );

    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();

    if (stdout.isNotEmpty) logger.info(stdout);
    if (stderr.isNotEmpty) logger.error(stderr);

    return result.exitCode;
  }
}

// ---------------------------------------------------------------------------
// dependency-graph sub-command
// ---------------------------------------------------------------------------

class _DependencyGraphSubCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format.',
        allowed: ['text', 'dot', 'mermaid', 'json'],
        defaultsTo: 'text',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path. Prints to stdout if not set.',
      );
  }

  @override
  String get name => 'dependency-graph';

  @override
  String get description =>
      'Visualize the dependency graph, annotating affected packages. '
      'Delegates to `dart run dependency_graph graph visualize`.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final format = argResults!['format'] as String;
    final outputPath = argResults!['output'] as String?;
    final logger = CliLogger();

    final affectedPaths = await _resolveAffected(baseBranch, logger);
    if (affectedPaths == null) return 1;

    if (affectedPaths.isEmpty) {
      logger.info('No packages affected by the changes.');
      return 0;
    }

    logger
      ..info('Comparing HEAD with $baseBranch...')
      ..info('Found ${affectedPaths.length} affected package(s)')
      ..info('Running: dart run dependency_graph graph visualize');

    final rootPath = MonorepoFinder.requireRoot();

    final args = [
      'run',
      'dependency_graph',
      'graph',
      'visualize',
      '--format',
      format,
      if (outputPath != null) ...['--output', outputPath],
    ];

    final result = await Process.run(
      'dart',
      args,
      workingDirectory: rootPath,
      runInShell: true,
    );

    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();

    if (stdout.isNotEmpty) {
      // Annotate lines that correspond to affected packages.
      final annotated = _annotateAffected(stdout, affectedPaths, rootPath);
      // ignore: avoid_print - stdout output passthrough
      print(annotated);
    }
    if (stderr.isNotEmpty) logger.error(stderr);

    return result.exitCode;
  }

  String _annotateAffected(
    String output,
    Set<String> affectedPaths,
    String rootPath,
  ) {
    // Collect affected package names for annotation.
    final allPackages = PackageScanner.scan(rootPath);
    final affectedNames = <String>{};

    for (final pkgPath in affectedPaths) {
      final fullPath = p.join(rootPath, pkgPath);
      for (final pkg in allPackages) {
        if (pkg.path == fullPath || pkg.path.endsWith('/$pkgPath')) {
          affectedNames.add(pkg.name);
          break;
        }
      }
    }

    return output
        .split('\n')
        .map((line) {
          for (final name in affectedNames) {
            if (line.contains(name)) return '$line  [AFFECTED]';
          }
          return line;
        })
        .join('\n');
  }
}

// ---------------------------------------------------------------------------
// coverage sub-command
// ---------------------------------------------------------------------------

class _CoverageSubCommand() extends Command<int> {
  this {
    argParser
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch or commit to compare against.',
        defaultsTo: 'main',
      )
      ..addFlag(
        'fail-fast',
        help: 'Stop on first package failure.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Run test coverage for affected packages only. '
      'Delegates to `dart run coverage_manager run --package <name>` '
      'for each affected package.';

  @override
  Future<int> run() async {
    final baseBranch = argResults!['base'] as String;
    final failFast = argResults!['fail-fast'] as bool;
    final logger = CliLogger();

    final affectedNames = await _resolveAffectedNames(baseBranch, logger);
    if (affectedNames == null) return 1;

    if (affectedNames.isEmpty) {
      logger.info('No packages affected by the changes.');
      return 0;
    }

    // Filter to packages that actually have tests.
    final rootPath = MonorepoFinder.requireRoot();
    final testableNames = affectedNames.where((name) {
      final pkg = PackageScanner.findPackage(rootPath, name);
      return pkg?.hasTests ?? false;
    }).toList()..sort();

    if (testableNames.isEmpty) {
      logger.info(
        'No affected packages have tests '
        '(${affectedNames.length} package(s) checked).',
      );
      return 0;
    }

    logger
      ..info('Comparing HEAD with $baseBranch...')
      ..info(
        'Found ${testableNames.length} testable affected package(s) '
        '(${affectedNames.length - testableNames.length} without tests skipped)',
      );

    var hasFailures = false;

    for (final name in testableNames) {
      logger.progress('[$name] Running coverage...');

      final result = await Process.run(
        'dart',
        ['run', 'coverage_manager', 'run', '--package', name],
        workingDirectory: rootPath,
        runInShell: true,
      );

      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();

      if (result.exitCode != 0) {
        hasFailures = true;
        logger.error('[$name] Failed (exit code: ${result.exitCode})');
        if (stderr.isNotEmpty) logger.error(stderr);
        if (stdout.isNotEmpty) logger.info(stdout);
        if (failFast) return 1;
      } else {
        if (stdout.isNotEmpty) logger.info(stdout);
        logger.success('[$name] Coverage collected.');
      }
    }

    return hasFailures ? 1 : 0;
  }
}
