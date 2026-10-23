import 'package:args/command_runner.dart';
import 'package:changelog_generator/src/services/changelog_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Writes a CHANGELOG.md entry from the commits since the last tag.
class ChangelogCommand() extends Command<int> {
  /// Creates a [ChangelogCommand].
  this {
    argParser
      ..addOption(
        'package',
        help: 'Package path; scopes commits, tag pattern and CHANGELOG.md.',
      )
      ..addOption(
        'tag-pattern',
        help: 'Glob of the tags to start from. Default: v*, or <package>-v*.',
      )
      ..addOption(
        'version',
        help: 'Version for the heading. Default: Unreleased.',
      )
      ..addFlag(
        'all',
        help: 'Also list chore, ci, docs, test, style and build commits.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Print the entry without writing.',
        negatable: false,
      );
  }

  @override
  String get name => 'changelog';

  @override
  String get description =>
      'Write a CHANGELOG.md entry grouped by Conventional Commit type.';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    try {
      final package = argResults!['package'] as String?;
      final pattern =
          argResults!['tag-pattern'] as String? ??
          ChangelogService.defaultPattern(package);
      final version = argResults!['version'] as String? ?? 'Unreleased';
      final service = ChangelogService(repoPath: MonorepoFinder.requireRoot());

      final tag = await service.latestTag(pattern);
      final commits = await service.commitsSince(tag, path: package);
      final body = service.renderBody(commits, all: argResults!['all'] as bool);
      if (body.isEmpty) {
        logger.info('No changes to list since ${tag ?? 'the first commit'}.');
        return 0;
      }
      if (argResults!['dry-run'] as bool) {
        logger.info(body);
        return 0;
      }

      final path = p.join(
        MonorepoFinder.requireRoot(),
        package ?? '',
        'CHANGELOG.md',
      );
      final written = service.write(path, version: version, body: body);
      if (written) {
        logger.success('Wrote $version to $path');
      } else {
        logger.warning('$path already has $version; left unchanged.');
      }
      return 0;
    } on Exception catch (e) {
      logger.error('Failed: $e');
      return 1;
    }
  }
}
