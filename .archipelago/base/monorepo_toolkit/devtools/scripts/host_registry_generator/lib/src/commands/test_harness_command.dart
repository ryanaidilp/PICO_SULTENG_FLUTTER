import 'package:args/command_runner.dart';
import 'package:host_registry_generator/src/commands/host_registry_command.dart';
import 'package:host_registry_generator/src/models/di_resolution_exception.dart';
import 'package:host_registry_generator/src/models/host_registry_app_not_found_exception.dart';
import 'package:host_registry_generator/src/models/host_registry_target_not_found_exception.dart';
import 'package:host_registry_generator/src/models/manifest_parse_exception.dart';
import 'package:host_registry_generator/src/services/host_registry_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Regenerates an app's `test/support/composition_root_harness.dart` from
/// every package's `archipelago: test_prerequisites` declaration, creating
/// the file when it does not exist.
///
/// Usage:
/// ```bash
/// monorepo_toolkit generate test-harness
/// monorepo_toolkit generate test-harness --app template_app
/// monorepo_toolkit generate test-harness --check
/// ```
class TestHarnessCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [TestHarnessCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help:
            'The app to update (directory name inside apps/). Auto-detected '
            'when the workspace has exactly one app with an injector.dart.',
      )
      ..addOption(
        'root',
        help:
            'Override the workspace root (defaults to the detected '
            'monorepo root).',
      )
      ..addFlag(
        'check',
        help:
            'Report drift without writing. Exits 1 if the harness would '
            'change.',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'test-harness';

  @override
  String get description =>
      "Regenerate an app's test/support/composition_root_harness.dart from "
      'each package archipelago: test_prerequisites declaration.';

  @override
  Future<int> run() async {
    final rootPath =
        (argResults?['root'] as String?) ?? MonorepoFinder.findRoot();
    if (rootPath == null) {
      _logger.error(
        'Could not find monorepo root. Run inside a Dart workspace or pass '
        '--root explicitly.',
      );
      return 1;
    }

    final injectorPath = resolveHostInjectorPath(
      rootPath: rootPath,
      appArg: argResults?['app'] as String?,
      logger: _logger,
    );
    if (injectorPath == null) return 1;

    final checkOnly = argResults?['check'] as bool? ?? false;
    try {
      final result = HostRegistryService(rootPath: rootPath)
          .generateTestHarness(
            targetHarnessPath: p.join(
              p.dirname(p.dirname(p.dirname(injectorPath))),
              testHarnessRelativePath,
            ),
            write: !checkOnly,
          );
      _logger.info('${result.prerequisites.length} test prerequisite(s):');
      for (final decl in result.prerequisites) {
        _logger.info('  - ${decl.packageName}::${decl.className}');
      }
      if (checkOnly && result.changed) {
        _logger.error(
          '${result.targetPath} is out of date. Run '
          '`dart run monorepo_toolkit generate test-harness` to fix.',
        );
        return 1;
      }
      _logger.success(
        result.changed
            ? 'Updated ${result.targetPath}.'
            : '${result.targetPath} already up to date (no change).',
      );
      return 0;
    } on ManifestParseException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on DiResolutionException catch (e) {
      _logger.error(e.message);
      return 1;
    } on HostRegistryTargetNotFoundException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on HostRegistryAppNotFoundException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on MarkerImbalanceException catch (e) {
      _logger.error(e.message);
      return 1;
    }
  }
}
