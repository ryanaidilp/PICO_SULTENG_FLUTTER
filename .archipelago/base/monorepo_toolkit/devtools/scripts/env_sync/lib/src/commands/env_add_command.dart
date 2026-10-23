import 'package:args/command_runner.dart';
import 'package:flavor_manager/flavor_manager.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to add a new environment variable.
///
/// Adds the variable to all flavor env classes, .env files,
/// and the main Env class.
class EnvAddCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [EnvAddCommand].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'add';

  @override
  String get description => 'Add a new environment variable to all flavors.';

  @override
  String get invocation => 'env add <VARIABLE_NAME>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      _logger
        ..error('Please provide a variable name.')
        ..info('Usage: env add <VARIABLE_NAME>')
        ..info('Example: melos env:add -- API_SECRET');
      return 64;
    }

    final variableName = argResults!.rest.first;

    // Validate variable name format
    if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(variableName)) {
      _logger
        ..error('Invalid variable name: $variableName')
        ..info('Variable names must:')
        ..info('  - Start with an uppercase letter')
        ..info('  - Contain only uppercase letters, numbers, and underscores')
        ..info('Examples: API_KEY, DATABASE_URL, SECRET_123');
      return 64;
    }

    try {
      final rootPath = MonorepoFinder.findRoot();
      if (rootPath == null) {
        _logger.error('Could not find monorepo root.');
        return 1;
      }

      final service = EnvService(rootPath: rootPath);
      await service.addEnvVariable(variableName);

      _logger
        ..info('Next steps:')
        ..info('  1. Add values to .env.{flavor} files')
        ..info('  2. Run: dart run monorepo_toolkit env switch <flavor>')
        ..info('  3. Run: dart run build_runner build');

      return 0;
    } on Exception catch (e) {
      _logger.error('Failed to add env variable: $e');
      return 1;
    }
  }
}
