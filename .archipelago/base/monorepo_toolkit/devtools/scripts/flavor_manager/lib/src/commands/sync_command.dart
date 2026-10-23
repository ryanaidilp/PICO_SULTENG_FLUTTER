import 'package:args/command_runner.dart';
import 'package:flavor_manager/src/models/global_flavor_settings.dart';
import 'package:flavor_manager/src/services/flavor_service.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to sync global flavor settings with individual app configs.
class SyncCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [SyncCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help: 'Sync only a specific app (syncs all if not specified).',
      )
      ..addFlag(
        'from-apps',
        help:
            'Sync from app configs to global settings '
            '(default: from global to apps).',
        negatable: false,
      )
      ..addFlag(
        'init',
        help: 'Initialize global settings from existing app configs.',
        negatable: false,
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'sync';

  @override
  String get description =>
      'Sync flavor settings between global config and app configs.';

  @override
  String get invocation => 'flavor sync [--app <app_name>] [--from-apps]';

  @override
  Future<int> run() async {
    final appName = argResults!['app'] as String?;
    final fromApps = argResults!['from-apps'] as bool;
    final init = argResults!['init'] as bool;

    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = FlavorService(rootPath: rootPath);

      if (init) {
        return await _initGlobalSettings(service, rootPath);
      }

      if (fromApps) {
        return await _syncFromApps(service, rootPath, appName);
      } else {
        return await _syncToApps(service, rootPath, appName);
      }
    } on Exception catch (e) {
      _logger.error('Failed to sync: $e');
      return 1;
    }
  }

  Future<int> _initGlobalSettings(
    FlavorService service,
    String rootPath,
  ) async {
    _logger.info('Initializing global flavor settings from app configs...');

    final configPath = GlobalFlavorSettings.getConfigPath(rootPath);
    var settings = GlobalFlavorSettings.fromFile(configPath);

    final apps = service.findAppsWithFlavors();
    if (apps.isEmpty) {
      _logger.warning('No apps with flavor configurations found.');
      return 0;
    }

    _logger.info('Found ${apps.length} app(s) with flavors:');

    for (final appName in apps) {
      final flavorizrConfig = service.getFlavorsForApp(appName);
      if (flavorizrConfig == null) continue;

      _logger.info('  - $appName: ${flavorizrConfig.flavorNames.join(', ')}');

      String? androidAppId;
      String? iosBundleId;

      if (flavorizrConfig.flavors.isNotEmpty) {
        final firstFlavor = flavorizrConfig.flavors.values.first;
        final androidId = firstFlavor.android?.applicationId;
        final iosId = firstFlavor.ios?.bundleId;

        if (androidId != null) {
          androidAppId = _extractBaseId(androidId);
        }
        if (iosId != null) {
          iosBundleId = _extractBaseId(iosId);
        }
      }

      settings.setApp(
        appName,
        AppFlavorSettings(
          name: appName,
          flavors: flavorizrConfig.flavorNames,
          androidAppId: androidAppId,
          iosBundleId: iosBundleId,
        ),
      );
    }

    settings = GlobalFlavorSettings(
      apps: settings.apps,
      defaults: const FlavorDefaults(
        suffixPattern: '.{flavor}',
        appNamePattern: '{app} ({Flavor})',
        defaultFlavors: ['development', 'staging', 'production'],
      ),
    );

    settings.save(configPath);
    _logger.success('Global settings initialized!');
    _logger.info('Config saved to: ${configPath.replaceFirst(rootPath, '.')}');

    return 0;
  }

  Future<int> _syncFromApps(
    FlavorService service,
    String rootPath,
    String? appName,
  ) async {
    _logger.info('Syncing from app configs to global settings...');

    final configPath = GlobalFlavorSettings.getConfigPath(rootPath);
    final settings = GlobalFlavorSettings.fromFile(configPath);

    final apps = appName != null ? [appName] : service.findAppsWithFlavors();

    for (final app in apps) {
      final flavorizrConfig = service.getFlavorsForApp(app);
      if (flavorizrConfig == null) {
        _logger.warning('App "$app" not found or has no flavorizr.yaml');
        continue;
      }

      final existing = settings.getApp(app);
      settings.setApp(
        app,
        AppFlavorSettings(
          name: app,
          flavors: flavorizrConfig.flavorNames,
          androidAppId: existing?.androidAppId,
          iosBundleId: existing?.iosBundleId,
        ),
      );

      _logger.info('  Synced $app: ${flavorizrConfig.flavorNames.join(', ')}');
    }

    settings.save(configPath);
    _logger.success('Global settings updated from app configs!');

    return 0;
  }

  Future<int> _syncToApps(
    FlavorService service,
    String rootPath,
    String? appName,
  ) async {
    _logger.info('Syncing from global settings to app configs...');

    final configPath = GlobalFlavorSettings.getConfigPath(rootPath);
    final settings = GlobalFlavorSettings.fromFile(configPath);

    if (settings.apps.isEmpty) {
      _logger
        ..warning('No apps configured in global settings.')
        ..info('Run "flavor sync --init" to initialize from existing configs.');
      return 64;
    }

    final apps = appName != null ? [appName] : settings.apps.keys.toList();

    for (final app in apps) {
      final appSettings = settings.getApp(app);
      if (appSettings == null) {
        _logger.warning('App "$app" not found in global settings');
        continue;
      }

      final existingConfig = service.getFlavorsForApp(app);
      if (existingConfig == null) {
        _logger.warning('App "$app" not found in apps/ directory');
        continue;
      }

      final toAdd = appSettings.flavors
          .where((f) => !existingConfig.flavorNames.contains(f))
          .toList();

      final extra = existingConfig.flavorNames
          .where((f) => !appSettings.flavors.contains(f))
          .toList();

      if (toAdd.isEmpty && extra.isEmpty) {
        _logger.info('  $app is in sync');
        continue;
      }

      if (toAdd.isNotEmpty) {
        _logger.info('  Adding to $app: ${toAdd.join(', ')}');
        for (final flavor in toAdd) {
          final flavorConfig = service.createDefaultFlavor(
            name: flavor,
            existingConfig: existingConfig,
          );
          service.addFlavor(appName: app, flavor: flavorConfig);
        }
      }

      if (extra.isNotEmpty) {
        _logger.warning(
          '  Extra flavors in $app (not in global): '
          '${extra.join(', ')}',
        );
      }
    }

    _logger.success('App configs synced from global settings!');
    return 0;
  }

  String _extractBaseId(String id) {
    const suffixes = [
      '.development',
      '.staging',
      '.production',
      '.dev',
      '.stg',
      '.prod',
    ];

    for (final suffix in suffixes) {
      if (id.endsWith(suffix)) {
        return id.substring(0, id.length - suffix.length);
      }
    }

    return id;
  }
}
