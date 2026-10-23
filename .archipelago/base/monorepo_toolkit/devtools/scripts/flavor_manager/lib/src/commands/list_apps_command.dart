import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/services/flavor_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to list all apps that have flavor configurations.
class ListAppsCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [ListAppsCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'list-apps';

  @override
  String get description => 'List all apps that have flavor configurations.';

  @override
  Future<int> run() async {
    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = FlavorService(rootPath: rootPath);
      final appsWithFlavors = service.findAppsWithFlavors();
      final allApps = service.findAllApps();

      if (allApps.isEmpty) {
        _logger.info('No apps found in the apps directory.');
        return 0;
      }

      _logger.info('Apps in monorepo:');

      for (final app in allApps) {
        final hasFlavors = appsWithFlavors.contains(app);
        final status = hasFlavors ? 'flavorizr.yaml' : 'no flavors';

        _logger.info('  $app - $status');

        if (hasFlavors) {
          final config = service.getFlavorsForApp(app);
          if (config != null) {
            final flavorNames = config.flavorNames.join(', ');
            _logger.info('    Flavors: $flavorNames');
          }
        }
      }

      return 0;
    } on Exception catch (e) {
      _logger.error('Failed to list apps: $e');
      return 1;
    }
  }
}
