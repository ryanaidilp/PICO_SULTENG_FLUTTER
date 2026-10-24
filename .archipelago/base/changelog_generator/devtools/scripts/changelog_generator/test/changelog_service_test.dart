import 'dart:io';

import 'package:changelog_generator/changelog_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory repo;
  late ChangelogService service;

  void git(List<String> args) {
    final r = Process.runSync('git', args, workingDirectory: repo.path);
    if (r.exitCode != 0) fail('git $args: ${r.stderr}');
  }

  void commit(String message, {String file = 'a.txt'}) {
    File(p.join(repo.path, file))
      ..createSync(recursive: true)
      ..writeAsStringSync('${DateTime.now().microsecondsSinceEpoch}');
    git(['add', '.']);
    git(['commit', '-q', '-m', message]);
  }

  setUp(() {
    repo = Directory.systemTemp.createTempSync('changelog_');
    git(['init', '-q']);
    git(['config', 'user.email', 't@example.com']);
    git(['config', 'user.name', 't']);
    git(['config', 'commit.gpgsign', 'false']);
    git(['config', 'tag.gpgsign', 'false']);
    service = ChangelogService(
      repoPath: repo.path,
      clock: () => DateTime(2026, 10, 5),
    );
  });

  tearDown(() => repo.deleteSync(recursive: true));

  group('ConventionalCommit.parse', () {
    test('reads type, scope and bang', () {
      final c = ConventionalCommit.parse('Feat(auth)!: drop legacy login');
      expect(c.type, 'feat');
      expect(c.scope, 'auth');
      expect(c.description, 'drop legacy login');
      expect(c.isBreaking, isTrue);
    });

    test('reads a BREAKING CHANGE footer', () {
      final c = ConventionalCommit.parse(
        'fix: rename flag',
        'Body.\n\nBREAKING CHANGE: --old is gone',
      );
      expect(c.isBreaking, isTrue);
      expect(c.breakingNote, '--old is gone');
    });

    test('keeps a non-conventional subject whole', () {
      final c = ConventionalCommit.parse('Update readme');
      expect(c.type, isNull);
      expect(c.description, 'Update readme');
    });
  });

  test('groups commits since the latest matching tag', () async {
    commit('feat: before the tag');
    git(['tag', 'v1.0.0']);
    git(['tag', 'other-v9.0.0']);
    commit('feat(ui): add button');
    commit('fix: crash on start');
    commit('perf: faster scan');
    commit('chore: bump deps');
    commit('Update readme');
    commit('refactor!: rename core', file: 'b.txt');

    final tag = await service.latestTag('v*');
    expect(tag, 'v1.0.0');
    final commits = await service.commitsSince(tag);
    final body = service.renderBody(commits);

    expect(body, contains('### Breaking changes\n\n- rename core'));
    expect(body, contains('### Features\n\n- ui: add button'));
    expect(body, contains('### Fixes\n\n- crash on start'));
    expect(body, contains('### Performance\n\n- faster scan'));
    expect(body, contains('### Other\n\n- Update readme'));
    expect(body, isNot(contains('before the tag')));
    expect(body, isNot(contains('bump deps')));
    expect(service.renderBody(commits, all: true), contains('bump deps'));
  });

  test('picks the highest version tag, not the newest name', () async {
    commit('feat: a');
    git(['tag', 'v1.2.0']);
    git(['tag', 'v1.10.0']);
    expect(await service.latestTag('v*'), 'v1.10.0');
  });

  test('scopes commits to a package path', () async {
    commit('feat: root thing');
    commit('feat: auth thing', file: 'packages/auth/x.txt');
    final commits = await service.commitsSince(null, path: 'packages/auth');
    final body = service.renderBody(commits);
    expect(body, contains('auth thing'));
    expect(body, isNot(contains('root thing')));
    expect(ChangelogService.defaultPattern('packages/auth'), 'auth-v*');
  });

  group('write', () {
    late String path;
    setUp(() => path = p.join(repo.path, 'CHANGELOG.md'));

    test('creates the file and is idempotent for a version', () {
      expect(
        service.write(path, version: '1.0.0', body: '### Fixes\n\n- a\n'),
        isTrue,
      );
      final first = File(path).readAsStringSync();
      expect(first, startsWith('# Changelog\n\n## 1.0.0 - 2026-10-05\n\n'));
      expect(
        service.write(path, version: '1.0.0', body: '### Fixes\n\n- b\n'),
        isFalse,
      );
      expect(File(path).readAsStringSync(), first);
    });

    test('puts a new version on top of older ones', () {
      File(path)
          .writeAsStringSync('# Changelog\n\n## 1.0.0 - 2026-01-01\n\nold\n');
      service.write(path, version: '1.1.0', body: 'new\n');
      final text = File(path).readAsStringSync();
      expect(text.indexOf('## 1.1.0'), lessThan(text.indexOf('## 1.0.0')));
      expect(text, contains('old'));
    });

    test('rewrites Unreleased in place', () {
      service.write(path, version: 'Unreleased', body: '- a\n');
      service.write(path, version: 'Unreleased', body: '- b\n');
      final text = File(path).readAsStringSync();
      expect(text, contains('- b'));
      expect(text, isNot(contains('- a')));
      expect('## Unreleased'.allMatches(text), hasLength(1));
    });
  });
}
