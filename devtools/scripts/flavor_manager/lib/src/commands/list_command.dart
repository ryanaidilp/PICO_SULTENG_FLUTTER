import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/services/flavor_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to list flavors for a specific app.
class ListFlavorsCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [ListFlavorsCommand].
  this {
    argParser.addOption(
      'app',
      abbr: 'a',
      help: 'The app name to list flavors for.',
      mandatory: true,
    );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'list';

  @override
  String get description => 'List all flavors for a specific app.';

  @override
  String get invocation => 'flavor list --app <app_name>';

  @override
  Future<int> run() async {
    final appName = argResults!['app'] as String;

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
        _logger.info('Available apps with flavors:');
        for (final app in service.findAppsWithFlavors()) {
          _logger.info('  - $app');
        }
        return 64;
      }

      if (config.flavors.isEmpty) {
        _logger.info('No flavors configured for "$appName".');
        return 0;
      }

      _logger.info('Flavors for $appName:');

      for (final entry in config.flavors.entries) {
        final flavor = entry.value;
        _logger.info('  ${flavor.name}');

        if (flavor.app?.name != null) {
          _logger.info('    App name: ${flavor.app!.name}');
        }
        if (flavor.android?.applicationId != null) {
          _logger.info('    Android ID: ${flavor.android!.applicationId}');
        }
        if (flavor.ios?.bundleId != null) {
          _logger.info('    iOS Bundle: ${flavor.ios!.bundleId}');
        }
      }

      return 0;
    } on Exception catch (e) {
      _logger.error('Failed to list flavors: $e');
      return 1;
    }
  }
}
