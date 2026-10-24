import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/services/flavor_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run flutter_flavorizr to generate flavor files.
class GenerateCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [GenerateCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help: 'The app name to generate flavors for.',
        mandatory: true,
      )
      ..addFlag(
        'splash',
        help: 'Also generate native splash screens for each flavor.',
        defaultsTo: true,
      )
      ..addFlag(
        'icons',
        help: 'Generate launcher icons (handled by flutter_flavorizr).',
        defaultsTo: true,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force regeneration even if inputs have not changed.',
        negatable: false,
      )
      ..addFlag(
        'check',
        help: 'Only check which flavors need regeneration (dry run).',
        negatable: false,
      )
      ..addFlag(
        'ide-configs',
        help: 'Generate IDE configurations (VSCode and JetBrains).',
        defaultsTo: true,
      )
      ..addFlag(
        'main-files',
        help: 'Generate flavor-based main entry point files.',
        defaultsTo: true,
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Run flutter_flavorizr to generate flavor configurations.';

  @override
  String get invocation => 'flavor generate --app <app_name>';

  @override
  Future<int> run() async {
    final appName = argResults!['app'] as String;
    final generateSplash = argResults!['splash'] as bool;
    final generateIcons = argResults!['icons'] as bool;
    final force = argResults!['force'] as bool;
    final checkOnly = argResults!['check'] as bool;
    final generateIdeConfigs = argResults!['ide-configs'] as bool;
    final generateMainFiles = argResults!['main-files'] as bool;

    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = FlavorService(rootPath: rootPath);

      final config = service.getFlavorsForApp(appName);
      if (config == null) {
        _logger.error(
          'App "$appName" not found or does not have a flavorizr.yaml file.',
        );
        return 64;
      }

      if (config.flavors.isEmpty) {
        _logger
          ..error('No flavors configured for "$appName".')
          ..info(
            'Add flavors first using: flavor add --app $appName '
            '--name <flavor_name>',
          );
        return 64;
      }

      // Check which flavors need regeneration
      final flavorsToGenerate = force
          ? config.flavorNames
          : service.getFlavorsNeedingRegeneration(appName);

      _logger.info('Checking flavors for $appName...');

      if (flavorsToGenerate.isEmpty) {
        _logger
          ..success('All flavors are up to date!')
          ..info('Use --force to regenerate all flavors.');
        return 0;
      }

      // Show status
      _logger.info('Flavor status:');
      for (final flavorName in config.flavorNames) {
        if (flavorsToGenerate.contains(flavorName)) {
          _logger.info('  * $flavorName (needs generation)');
        } else {
          _logger.info('  + $flavorName (up to date)');
        }
      }

      if (checkOnly) {
        _logger.info(
          '${flavorsToGenerate.length} flavor(s) need regeneration.',
        );
        return 0;
      }

      _logger.info(
        'Generating ${flavorsToGenerate.length} flavor(s): '
        '${flavorsToGenerate.join(', ')}',
      );

      // Step 1: Run flutter_flavorizr.
      //
      // flutter_flavorizr is what generates Android productFlavors, iOS
      // schemes, and the assemble<Flavor>Debug Gradle tasks. It must
      // ALWAYS run — gating it on the --icons flag (the previous bug)
      // silently broke Android builds with "Task 'assembleDevelopmentDebug'
      // not found".
      //
      // The --icons flag is honored by temporarily filtering icon-related
      // entries out of flavorizr.yaml's `instructions:` list before the
      // run, then restoring the file afterwards. When the brick post_gen
      // calls flavor_manager with --no-icons, flutter_launcher_icons
      // produces the per-flavor icons separately so flavorizr's icon
      // step would just be wasted work (and overwritten).
      _logger.info('Step 1: Running flutter_flavorizr...');
      final exitCode = await service.generateFlavors(
        appName,
        excludeIcons: !generateIcons,
      );
      if (exitCode != 0) {
        _logger.error('flutter_flavorizr failed with exit code $exitCode');
        return 1;
      }
      _logger.success('flutter_flavorizr completed successfully!');

      // Step 2: Generate native splash
      if (generateSplash && service.hasNativeSplash(appName)) {
        _logger.info('Step 2: Generating native splash screens...');
        final splashExitCode = await service.generateNativeSplash(appName);
        if (splashExitCode != 0) {
          _logger.error(
            'Native splash generation failed with exit code $splashExitCode',
          );
          return 1;
        }
        _logger.success('Native splash generation completed successfully!');
      }

      // Step 3: Generate IDE configurations
      if (generateIdeConfigs) {
        _logger.info('Step 3: Generating IDE configurations...');
        service.generateAllIdeConfigs();
        _logger.success('IDE configurations generated successfully!');
      }

      // Step 4: Generate flavor-based main entry point files
      if (generateMainFiles) {
        _logger.info('Step 4: Generating flavor main entry point files...');
        await service.generateFlavorMainFiles(appName);
        _logger.success('Main entry point files generated successfully!');
      }

      // Update cache for generated flavors
      for (final flavorName in config.flavorNames) {
        service.markFlavorGenerated(appName, flavorName);
      }

      _logger
        ..success('All flavor generation completed successfully!')
        ..info('You can now run your app with a specific flavor:');

      for (final flavorName in config.flavorNames) {
        _logger.info('  flutter run --flavor $flavorName');
      }

      return 0;
    } on AppNotFoundException catch (e) {
      _logger.error(e.toString());
      return 64;
    } on Exception catch (e) {
      _logger.error('Failed to generate flavors: $e');
      return 1;
    }
  }
}
