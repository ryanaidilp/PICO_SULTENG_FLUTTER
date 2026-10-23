import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/dependency_audit.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Rewrites every direct pin of one package to a single constraint.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit deps align <package> [<constraint>]
/// ```
class DepsAlignCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsAlignCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'align';

  @override
  String get description =>
      'Set every direct pin of a package to one constraint '
      '(default: the highest in use), then run dart pub get.';

  @override
  String get invocation => 'deps align <package> [<constraint>]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      _logger.error('Usage: $invocation');
      return 64;
    }
    final root = MonorepoFinder.findRoot();
    if (root == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    final package = rest.first;
    final owners = [
      for (final p in await readWorkspacePins(root))
        if (p.pinOf(package) != null) p,
    ];
    if (owners.isEmpty) {
      _logger.error('No workspace package pins "$package" directly.');
      return 1;
    }

    final String constraint;
    try {
      if (rest.length > 1) VersionConstraint.parse(rest[1]);
      constraint = rest.length > 1
          ? rest[1]
          : highestConstraint(owners.map((p) => p.pinOf(package)!));
    } on FormatException catch (e) {
      _logger.error('Invalid constraint: ${e.message}');
      return 64;
    }

    var changed = 0;
    for (final p in owners) {
      final file = File(p.path);
      final updated = alignPubspec(
        file.readAsStringSync(),
        package,
        constraint,
      );
      if (updated == null) continue;
      file.writeAsStringSync(updated);
      changed++;
      _logger.info('${p.name}: $package -> $constraint');
    }
    if (changed == 0) {
      _logger.success('$package is already $constraint everywhere.');
      return 0;
    }

    _logger.progress('Running dart pub get');
    final result = await ShellRunner.runDart([
      'pub',
      'get',
    ], workingDirectory: root);
    if (result.exitCode != 0) {
      _logger
        ..error('dart pub get failed after aligning $package:')
        ..info('${result.stdout}${result.stderr}'.trim())
        ..info('Run "deps diagnose" for a summary.');
      return 1;
    }
    _logger.success('Aligned $package to $constraint in $changed package(s).');
    return 0;
  }
}
