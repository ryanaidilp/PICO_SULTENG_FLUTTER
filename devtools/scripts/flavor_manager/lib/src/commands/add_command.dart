import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/services/flavor_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to add a new flavor to an app.
class AddFlavorCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [AddFlavorCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help: 'The app name to add the flavor to.',
        mandatory: true,
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'The flavor name (e.g., qa, uat, demo).',
        mandatory: true,
      )
      ..addOption(
        'app-name',
        help:
            'Custom app name suffix (e.g., "[QA]"). '
            'Defaults to "[FLAVOR_NAME]".',
      )
      ..addOption(
        'suffix',
        abbr: 's',
        help:
            'Bundle ID suffix (e.g., ".qa"). '
            'Defaults to ".<flavor_name>".',
      )
      ..addFlag(
        'generate',
        abbr: 'g',
        help: 'Run flutter_flavorizr after adding the flavor.',
        negatable: false,
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'add';

  @override
  String get description => 'Add a new flavor to an app.';

  @override
  String get invocation => 'flavor add --app <app_name> --name <flavor_name>';

  @override
  Future<int> run() async {
    final appName = argResults!['app'] as String;
    final flavorName = argResults!['name'] as String;
    final appNameSuffix = argResults!['app-name'] as String?;
    final bundleIdSuffix = argResults!['suffix'] as String?;
    final shouldGenerate = argResults!['generate'] as bool;

    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = FlavorService(rootPath: rootPath);

      // Validate flavor name
      if (!service.isValidFlavorName(flavorName)) {
        _logger
          ..error('Invalid flavor name: "$flavorName"')
          ..info('Flavor names must:')
          ..info('  - Start with a lowercase letter')
          ..info(
            '  - Contain only lowercase letters, numbers, and underscores',
          );
        return 64;
      }

      // Check if app exists
      final config = service.getFlavorsForApp(appName);
      if (config == null) {
        _logger.error(
          'App "$appName" not found or does not have a flavorizr.yaml file.',
        );
        return 64;
      }

      // Check if flavor already exists
      if (config.flavors.containsKey(flavorName)) {
        _logger.error('Flavor "$flavorName" already exists in "$appName".');
        return 64;
      }

      // Create the flavor configuration
      final flavor = service.createDefaultFlavor(
        name: flavorName,
        existingConfig: config,
        appNameSuffix: appNameSuffix,
        bundleIdSuffix: bundleIdSuffix,
      );

      // Display what will be added
      _logger
        ..info('Adding flavor $flavorName to $appName...')
        ..info('Configuration:')
        ..info('  Flavor name: $flavorName')
        ..info('  App name: ${flavor.app?.name ?? "N/A"}')
        ..info('  Android ID: ${flavor.android?.applicationId ?? "N/A"}')
        ..info('  iOS Bundle: ${flavor.ios?.bundleId ?? "N/A"}');

      // Add the flavor
      service.addFlavor(appName: appName, flavor: flavor);

      _logger.success('Flavor "$flavorName" added successfully!');

      // Regenerate IDE configs (.run/ + .vscode/launch.json, tasks.json)
      // so the new flavor is immediately discoverable in IntelliJ and VSCode
      // without requiring a separate `flavor generate --ide-configs` call.
      try {
        service.generateAllIdeConfigs();
        _logger.info('IDE configs updated for VSCode and IntelliJ.');
      } on Exception catch (e) {
        _logger.warning('Failed to update IDE configs: $e');
      }

      // Run flutter_flavorizr if requested
      if (shouldGenerate) {
        final exitCode = await service.generateFlavors(appName);
        if (exitCode != 0) {
          _logger.error('flutter_flavorizr failed with exit code $exitCode');
          return 1;
        }
      } else {
        _logger
          ..info('Next steps:')
          ..info('  1. Add launcher icons for $flavorName')
          ..info(
            '  2. Run: dart run monorepo_toolkit flavor generate '
            '--app $appName',
          )
          ..info('  3. Test: flutter run --flavor $flavorName');
      }

      return 0;
    } on FlavorExistsException catch (e) {
      _logger.error(e.toString());
      return 64;
    } on AppNotFoundException catch (e) {
      _logger.error(e.toString());
      return 64;
    } on Exception catch (e) {
      _logger.error('Failed to add flavor: $e');
      return 1;
    }
  }
}
