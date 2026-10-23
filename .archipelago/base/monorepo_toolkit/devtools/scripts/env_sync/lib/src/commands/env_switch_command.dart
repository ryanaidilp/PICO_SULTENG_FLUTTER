import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to switch the active environment flavor.
///
/// Copies values from `.env.<flavor>` to `.env` so that build_runner
/// picks up the correct secrets for the requested flavor.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit env switch development
/// dart run monorepo_toolkit env switch production --app-config-path shared/app_config
/// ```
///
/// Pass `--if-missing` to seed `.env` only when it does not already exist
/// (a no-op, not an overwrite, when it does) and to tolerate a missing
/// source `.env.<flavor>` instead of erroring — the shape a `bootstrap.post`
/// melos hook needs, since it runs unattended on every `melos bootstrap`
/// and must neither clobber a developer's real `.env` nor fail a project
/// that hasn't scaffolded env files at all (Archipelago-hol4).
class EnvSwitchCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [EnvSwitchCommand].
  this {
    argParser
      ..addOption(
        'app-config-path',
        help: 'Path to shared/app_config (default: shared/app_config)',
        defaultsTo: 'shared/app_config',
      )
      ..addFlag(
        'if-missing',
        help:
            'Only write .env if it does not already exist yet, instead of '
            'unconditionally overwriting it. Also treats a missing source '
            '.env.<flavor> as a no-op instead of an error, so this is safe '
            'to run unattended (e.g. from a bootstrap hook) against a '
            'project that has not scaffolded env files at all.',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'switch';

  @override
  String get description =>
      'Copy values from .env.<flavor> to .env so build_runner picks them up.';

  @override
  String get invocation => 'env switch <flavor>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      _logger.error('Usage: env switch <flavor>');
      return 64;
    }

    final flavor = rest.first;
    final appConfigPath = argResults!['app-config-path'] as String;
    final ifMissing = argResults!['if-missing'] as bool;

    final sourcePath = path.join(appConfigPath, '.env.$flavor');
    final targetPath = path.join(appConfigPath, '.env');

    if (ifMissing && File(targetPath).existsSync()) {
      _logger.info('$targetPath already exists — skipping.');
      return 0;
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      if (ifMissing) {
        _logger.info(
          '$sourcePath not found — nothing to seed $targetPath from, '
          'skipping.',
        );
        return 0;
      }
      _logger.error('Error: $sourcePath not found.');
      _logger.info('Available flavors:');
      for (final f in _listAvailableFlavors(appConfigPath)) {
        _logger.info('  - $f');
      }
      return 1;
    }

    // Atomic write: copy contents (NOT symlink — works on all platforms).
    final contents = source.readAsStringSync();
    File(targetPath).writeAsStringSync(contents);

    _logger.success('Switched env to: $flavor');
    _logger.info('  $sourcePath -> $targetPath');
    _logger.info('Next: dart run build_runner build (regenerate env.g.dart)');
    return 0;
  }

  List<String> _listAvailableFlavors(String appConfigPath) {
    final dir = Directory(appConfigPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => path.basename(f.path))
        .where((n) => n.startsWith('.env.') && n != '.env.example')
        .map((n) => n.substring('.env.'.length))
        .toList()
      ..sort();
  }
}
