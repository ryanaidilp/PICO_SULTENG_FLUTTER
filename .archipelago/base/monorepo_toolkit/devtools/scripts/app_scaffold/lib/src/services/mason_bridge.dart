import 'package:shared_scripts/shared_scripts.dart';

/// A reusable helper for invoking Mason CLI commands.
///
/// Provides methods to check if Mason is installed, if a specific brick
/// is available, and to run `mason make` with template variables.
///
/// This bridge is designed to be reusable across multiple brick-based
/// commands (app scaffold, feature create, etc.).
///
/// ```dart
/// final bridge = MasonBridge(logger: logger);
///
/// if (!await bridge.isMasonInstalled()) {
///   logger.error('Mason is not installed.');
///   return;
/// }
///
/// if (!await bridge.isBrickAvailable('app_scaffold')) {
///   logger.error('Brick not found.');
///   return;
/// }
///
/// await bridge.makeBrick(
///   brickName: 'app_scaffold',
///   variables: {'name': 'my_app', 'org': 'com.example'},
///   outputDir: 'apps/',
/// );
/// ```
class MasonBridge({CliLogger? logger}) {
  /// Creates a new [MasonBridge].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  /// Checks whether the Mason CLI is installed and accessible.
  ///
  /// Returns `true` if `mason --version` exits with code 0.
  Future<bool> isMasonInstalled() async {
    try {
      final result = await ShellRunner.run('mason --version');
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether a brick is available (bundled or globally activated).
  ///
  /// Runs `mason list` and searches for [brickName] in the output.
  /// Checks both local (bundled) and global bricks.
  Future<bool> isBrickAvailable(
    String brickName, {
    String? workingDirectory,
  }) async {
    // Check local bricks first
    final localResult = await ShellRunner.run(
      'mason list',
      workingDirectory: workingDirectory,
    );

    if (localResult.exitCode == 0) {
      final output = localResult.stdout.toString();
      if (output.contains(brickName)) return true;
    }

    // Check global bricks
    final globalResult = await ShellRunner.run('mason list -g');
    if (globalResult.exitCode == 0) {
      final output = globalResult.stdout.toString();
      if (output.contains(brickName)) return true;
    }

    return false;
  }

  /// Runs `mason make` for a given brick with template variables.
  ///
  /// Returns the exit code from the mason process.
  ///
  /// The [variables] map is converted to `--<key> <value>` flags.
  /// The [outputDir] sets `--output-dir`.
  Future<int> makeBrick({
    required String brickName,
    required Map<String, String> variables,
    required String outputDir,
    String? workingDirectory,
  }) async {
    final varArgs = variables.entries
        .map((e) => '--${e.key} ${e.value}')
        .join(' ');

    final command =
        'mason make $brickName $varArgs '
        '--output-dir $outputDir --on-conflict skip';

    _logger.info('Running: $command');

    final result = await ShellRunner.run(
      command,
      workingDirectory: workingDirectory,
      verbose: true,
    );

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) {
        _logger.error('Mason error: $stderr');
      }
    }

    return result.exitCode;
  }

  /// Runs post-generation setup tasks.
  ///
  /// Typically called after a brick has been generated to resolve
  /// dependencies and update the workspace.
  Future<int> runPostSetup({
    required String appDir,
    required String rootPath,
  }) async {
    _logger.info('Running post-setup...');

    // Run dart pub get from the workspace root
    _logger.info('Resolving dependencies...');
    final pubGetResult = await ShellRunner.runDart(
      ['pub', 'get'],
      workingDirectory: rootPath,
      verbose: true,
    );

    if (pubGetResult.exitCode != 0) {
      _logger.error('Failed to resolve dependencies.');
      return pubGetResult.exitCode;
    }

    // Update workspace list
    _logger.info('Updating workspace...');
    final workspaceResult = await ShellRunner.runDart(
      ['run', 'monorepo_toolkit', 'workspace', 'setup'],
      workingDirectory: rootPath,
      verbose: true,
    );

    if (workspaceResult.exitCode != 0) {
      _logger.error('Failed to update workspace.');
      return workspaceResult.exitCode;
    }

    return 0;
  }
}
