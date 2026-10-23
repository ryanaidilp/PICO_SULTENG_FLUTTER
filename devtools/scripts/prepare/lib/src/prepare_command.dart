import 'package:args/command_runner.dart';
import 'package:prepare/src/prepare_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command that prepares the workspace for a flavor before a Flutter build.
///
/// Composes env-switch + envied regeneration + build-prepare into a single
/// idempotent step. Designed to run on every launch: when the workspace is
/// already prepared for the requested `(flavor, mode)`, it short-circuits.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit prepare --flavor development
/// dart run monorepo_toolkit prepare --flavor production
/// ```
class PrepareCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [PrepareCommand].
  this {
    argParser
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'The flavor to prepare (e.g. development, staging, production).',
      )
      ..addOption(
        'mode',
        abbr: 'm',
        help:
            'Dependency swap direction. `auto` lets the flavor decide: '
            'internal_flavors keep the debug tooling, every other flavor '
            'gets the noop twins (ADR-035).',
        allowed: ['auto', 'debug', 'release'],
        defaultsTo: 'auto',
      )
      ..addOption(
        'app-config-path',
        help: 'Path to shared/app_config (default: shared/app_config).',
        defaultsTo: 'shared/app_config',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'prepare';

  @override
  String get description =>
      'Prepare the workspace for a flavor (env switch + envied regen + '
      'build-prepare) before flutter run/build.';

  @override
  String get invocation =>
      'monorepo_toolkit prepare --flavor <flavor> [--mode auto|debug|release]';

  @override
  Future<int> run() async {
    final flavor = argResults?['flavor'] as String?;
    if (flavor == null || flavor.isEmpty) {
      _logger.error('Error: --flavor is required.');
      _logger.info('Usage: $invocation');
      return 64;
    }

    final mode = argResults!['mode'] as String;
    final appConfigPath = argResults!['app-config-path'] as String;

    final rootPath = MonorepoFinder.findRoot();
    if (rootPath == null) {
      _logger.error(
        'Could not find monorepo root. Run from inside a Dart workspace '
        'with a pubspec.yaml containing a workspace: key.',
      );
      return 1;
    }

    try {
      await prepareWorkspace(
        rootPath: rootPath,
        flavor: flavor,
        mode: mode,
        appConfigPath: appConfigPath,
        logger: _logger,
      );
      return 0;
    } on PrepareException catch (e) {
      _logger.error(e.message);
      return 1;
    }
  }
}
