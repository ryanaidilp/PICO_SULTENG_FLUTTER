import 'dart:io';

import 'package:build_prepare/build_prepare.dart';
import 'package:path/path.dart' as p;
import 'package:prepare/src/prepare_state.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Outcome of a [prepareWorkspace] call.
enum PrepareOutcome() {
  /// Full prepare ran (env switch + envied regen + build-prepare).
  prepared,

  /// State already matched the requested flavor/mode — nothing to do.
  skipped,
}

/// Prepares the workspace for [flavor] in [mode] before a Flutter build.
///
/// Steps (only when the recorded state does not already match):
///   1. Copy `<appConfigPath>/.env.<flavor>` -> `<appConfigPath>/.env`.
///   2. Regenerate envied (`build_runner build`) in `<appConfigPath>` so
///      `env.g.dart` bakes the new flavor's values.
///   3. Apply the build-prepare dependency swap for [flavor]; [mode] `auto`
///      lets the flavor pick the direction, `debug`/`release` force it.
///   4. Write `.prepare.state.json` recording `{flavor, mode}`.
///
/// Idempotency: when `.prepare.state.json` already records the requested
/// `(flavor, mode)` AND the `.env` artifact is present, returns
/// [PrepareOutcome.skipped] without doing the expensive work.
///
/// Returns the [PrepareOutcome]. Throws [PrepareException] on any failure so
/// callers (CLI command, `run`) can abort the launch with a non-zero code.
Future<PrepareOutcome> prepareWorkspace({
  required String rootPath,
  required String flavor,
  required String mode,
  String appConfigPath = 'shared/app_config',
  CliLogger? logger,
}) async {
  final log = logger ?? CliLogger();

  final absAppConfig = p.join(rootPath, appConfigPath);
  final envSource = File(p.join(absAppConfig, '.env.$flavor'));
  final envTarget = File(p.join(absAppConfig, '.env'));

  if (!envSource.existsSync()) {
    final available = _listAvailableFlavors(absAppConfig);
    throw PrepareException(
      'Error: ${p.relative(envSource.path, from: rootPath)} not found.'
      '${available.isEmpty ? '' : '\nAvailable flavors: ${available.join(', ')}'}',
    );
  }

  // --- Idempotency check ---
  final state = PrepareState.load(rootPath);
  if (state != null && state.matches(flavor, mode) && envTarget.existsSync()) {
    log.info('Already prepared for $flavor/$mode — skipping.');
    return PrepareOutcome.skipped;
  }

  // --- 1. env switch (copy contents, never symlink) ---
  envTarget.writeAsStringSync(envSource.readAsStringSync());
  log.info('Switched env to $flavor (.env.$flavor -> .env).');

  // --- 2. Regenerate envied (slow — only on cache miss) ---
  log.progress('Regenerating env config for $flavor…');
  final genResult = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: absAppConfig,
    runInShell: Platform.isWindows,
  );
  if (genResult.exitCode != 0) {
    throw PrepareException(
      'Error: env config regeneration failed (build_runner exited '
      '${genResult.exitCode}).\n${genResult.stdout}\n${genResult.stderr}',
    );
  }

  // --- 3. build-prepare dependency swap for mode, filtered by flavor ---
  log.progress('Applying build-prepare ($mode) for $flavor…');
  final swapExit = await BuildPrepareRunner().run([
    if (mode != 'auto') mode,
    '--flavor',
    flavor,
  ]);
  if (swapExit != 0) {
    throw PrepareException(
      'Error: build-prepare ($mode) failed (exit $swapExit).',
    );
  }

  // --- 4. Persist state ---
  PrepareState.save(rootPath, PrepareState(flavor: flavor, mode: mode));

  log.success('Prepared workspace for $flavor/$mode.');
  return PrepareOutcome.prepared;
}

List<String> _listAvailableFlavors(String appConfigPath) {
  final dir = Directory(appConfigPath);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<File>()
      .map((f) => p.basename(f.path))
      .where((n) => n.startsWith('.env.') && n != '.env.example')
      .map((n) => n.substring('.env.'.length))
      .toList()
    ..sort();
}

/// Thrown when [prepareWorkspace] cannot complete. A pre-launch hook MUST
/// fail the launch when this is raised — never silently continue.
class const PrepareException(
  /// The user-facing error message.
  final String message,
) implements Exception {
  /// Creates a [PrepareException] with a user-facing [message].
  this;

  @override
  String toString() => message;
}
