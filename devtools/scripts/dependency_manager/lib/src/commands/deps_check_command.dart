import 'package:args/command_runner.dart';
import 'package:dependency_manager/src/services/dependency_audit.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Read-only audit of directly pinned third-party dependencies.
///
/// Reports packages pinned with different constraints in several workspace
/// packages, and pins of packages the `dependencies` barrels already
/// re-export (ADR-043). Exits 1 when it finds either.
class DepsCheckCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [DepsCheckCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'check';

  @override
  String get description =>
      'List drifting or barrel-duplicated direct dependency pins.';

  @override
  Future<int> run() async {
    final root = MonorepoFinder.findRoot();
    if (root == null) {
      _logger.error('Could not find monorepo root.');
      return 1;
    }

    final packages = await readWorkspacePins(root);
    final drift = findDrift(packages);
    final duplicates = findBarrelDuplicates(packages);

    for (final e in drift.entries) {
      _logger.warning('${e.key} is pinned with ${e.value.length} constraints:');
      for (final c in e.value.entries) {
        _logger.info('  ${c.key}: ${c.value.join(', ')}');
      }
      _logger.info('  fix: deps align ${e.key}');
    }
    for (final e in duplicates.entries) {
      _logger.warning(
        '${e.key} pins ${e.value.join(', ')}, already re-exported by the '
        'dependencies barrels (ADR-043); remove the pin.',
      );
    }

    if (drift.isEmpty && duplicates.isEmpty) {
      _logger.success('No drifting or barrel-duplicated pins.');
      return 0;
    }
    return 1;
  }
}
