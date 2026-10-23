import 'package:args/command_runner.dart';
import 'package:flavor_manager/flavor_manager.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to initialize environment configuration.
///
/// Creates per-flavor env classes, .env template files, and updates
/// the main Env class and FlavorStatus enum.
///
/// Safe to re-run: if `env.dart` already declares one or more
/// `@EnviedField()`s, this is a no-op for `env.dart`/`flavor.dart` by
/// default — it only scaffolds any missing `.env.<flavor>` files so a
/// fresh checkout isn't blocked, sourcing variable names from
/// `.env.example` when present. Pass `--force` to regenerate
/// `env.dart`/`flavor.dart` from scratch, which discards any hand-added
/// fields and doc comments.
class EnvInitCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [EnvInitCommand].
  this {
    argParser
      ..addMultiOption(
        'var',
        abbr: 'v',
        help:
            'Environment variables to include (can be specified multiple '
            'times). Defaults to the variables declared in .env.example, '
            'falling back to API_BASE_URL/AES_KEY for a from-scratch '
            'package with no .env.example.',
      )
      ..addFlag(
        'force',
        help:
            'Regenerate env.dart/flavor.dart even if already initialized. '
            'Discards any hand-added fields and doc comments.',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize environment configuration for all flavors.';

  @override
  String get invocation => 'env init [--var API_KEY --var SECRET] [--force]';

  @override
  Future<int> run() async {
    final explicitVariables = argResults!.wasParsed('var')
        ? argResults!['var'] as List<String>
        : null;
    final force = argResults!['force'] as bool;

    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = EnvService(rootPath: rootPath);

      if (service.isInitialized() && !force) {
        final existing = service.getExistingEnvVariables();
        _logger
          ..warning(
            'env.dart is already initialized with ${existing.length} '
            'variable(s): ${existing.join(', ')}.',
          )
          ..info('Skipping regeneration of env.dart/flavor.dart.')
          ..info('Next steps:')
          ..info('  - Use `env add <VAR>` to add a new variable.')
          ..info('  - Use `env sync` to resync FlavorStatus with flavors.yaml.')
          ..info(
            '  - Pass --force to regenerate from scratch (this deletes '
            'any hand-added fields and doc comments).',
          );

        final created = await service.ensureEnvTemplateFiles(
          envVariables: explicitVariables,
        );
        if (created.isNotEmpty) {
          _logger.info(
            'Scaffolded missing .env.<flavor> file(s): '
            '${created.join(', ')}',
          );
        }

        return 0;
      }

      await service.initializeEnv(envVariables: explicitVariables);

      _logger
        ..info('Next steps:')
        ..info('  1. Fill in values in .env.{flavor} files')
        ..info('  2. Run: dart run monorepo_toolkit env switch <flavor>')
        ..info('  3. Run: dart run build_runner build')
        ..info('  4. Import: package:app_config/app_config.dart');

      return 0;
    } on Exception catch (e) {
      _logger.error('Failed to initialize env: $e');
      return 1;
    }
  }
}
