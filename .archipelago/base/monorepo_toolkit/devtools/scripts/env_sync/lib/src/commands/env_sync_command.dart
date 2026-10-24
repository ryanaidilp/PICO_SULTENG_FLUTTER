import 'package:args/command_runner.dart';
import 'package:flavor_manager/flavor_manager.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to sync env config with the flavors in flavors.yaml.
///
/// Updates the FlavorStatus enum and adds missing `.env.<flavor>` files,
/// keys and `env.dart` fields. Existing values and fields are kept.
class EnvSyncCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [EnvSyncCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'sync';

  @override
  String get description =>
      'Sync FlavorStatus enum with configured flavors in flavors.yaml.';

  @override
  Future<int> run() async {
    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = EnvService(rootPath: rootPath);
      final flavors = service.getFlavorsFromSettings();
      _logger.info('Syncing FlavorStatus with flavors: ${flavors.join(', ')}');

      await service.syncEnv();

      _logger.success('Env config synced!');

      return 0;
    } on Exception catch (e) {
      _logger.error('Failed to sync flavors: $e');
      return 1;
    }
  }
}
