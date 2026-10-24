import 'dart:io';

import 'package:changelog_generator/src/models/conventional_commit.dart';
import 'package:path/path.dart' as p;

/// Builds and writes changelog sections from git history.
class ChangelogService({
  /// Git working directory (the repository root).
  required final String repoPath,

  /// Clock for the section date.
  final DateTime Function()? clock,
}) {
  /// Creates a [ChangelogService].
  this;

  /// Types left out unless `all` is set.
  static const quietTypes = {'chore', 'ci', 'docs', 'test', 'style', 'build'};

  /// Newest tag matching [pattern] by version order, or `null`.
  Future<String?> latestTag(String pattern) async {
    final out = await _git(['tag', '--list', pattern, '--sort=-v:refname']);
    final tags = out.split('\n').where((t) => t.trim().isNotEmpty);
    return tags.isEmpty ? null : tags.first.trim();
  }

  /// Non-merge commits after [tag] (all history when null), newest first,
  /// limited to [path] when given.
  Future<List<ConventionalCommit>> commitsSince(
    String? tag, {
    String? path,
  }) async {
    final out = await _git([
      'log',
      '--no-merges',
      '--format=%s%x1f%b%x1e',
      if (tag != null) '$tag..HEAD',
      if (path != null) ...['--', path],
    ]);
    return [
      for (final record in out.split('\x1e'))
        if (record.trim().isNotEmpty)
          ConventionalCommit.parse(
            record.split('\x1f').first.trim(),
            record.split('\x1f').skip(1).join('\x1f'),
          ),
    ];
  }

  /// Renders the section body (no heading), or an empty string when nothing
  /// is worth listing.
  String renderBody(List<ConventionalCommit> commits, {bool all = false}) {
    final groups = <String, List<String>>{};
    for (final c in commits) {
      if (!all && !c.isBreaking && quietTypes.contains(c.type)) continue;
      final scope = c.scope == null ? '' : '${c.scope}: ';
      if (c.isBreaking) {
        groups
            .putIfAbsent('Breaking changes', () => [])
            .add('$scope${c.breakingNote ?? c.description}');
        continue;
      }
      final heading = switch (c.type) {
        'feat' => 'Features',
        'fix' => 'Fixes',
        'perf' => 'Performance',
        _ => 'Other',
      };
      groups.putIfAbsent(heading, () => []).add('$scope${c.description}');
    }
    final buffer = StringBuffer();
    for (final heading in const [
      'Breaking changes',
      'Features',
      'Fixes',
      'Performance',
      'Other',
    ]) {
      final lines = groups[heading];
      if (lines == null) continue;
      buffer.writeln('### $heading\n');
      for (final line in lines) {
        buffer.writeln('- $line');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Puts a `## [version] - date` section on top of [changelogPath].
  ///
  /// Returns false and leaves the file alone when [version] already has a
  /// heading. `Unreleased` is replaced instead, so it can be regenerated.
  bool write(
    String changelogPath, {
    required String version,
    required String body,
  }) {
    final file = File(changelogPath);
    final existing = file.existsSync() ? file.readAsStringSync() : '';
    final unreleased = version.toLowerCase() == 'unreleased';
    final sections = RegExp(r'^## .*$', multiLine: true).allMatches(existing);
    final heading = RegExp('^## \\[?${RegExp.escape(version)}\\]?( |\$)');

    for (final (i, m) in sections.indexed) {
      if (!heading.hasMatch(m.group(0)!)) continue;
      if (!unreleased) return false;
      final end = i + 1 < sections.length
          ? sections.elementAt(i + 1).start
          : existing.length;
      file.writeAsStringSync(
        existing.replaceRange(
          m.start,
          end,
          _section(version, body, unreleased),
        ),
      );
      return true;
    }

    final at = sections.isEmpty ? existing.length : sections.first.start;
    var head = existing.substring(0, at);
    if (head.trim().isEmpty) {
      head = '# Changelog\n\n';
    } else if (!head.endsWith('\n\n')) {
      head = '${head.trimRight()}\n\n';
    }
    file.createSync(recursive: true);
    file.writeAsStringSync(
      '$head${_section(version, body, unreleased)}${existing.substring(at)}',
    );
    return true;
  }

  String _section(String version, String body, bool unreleased) {
    final now = (clock ?? DateTime.now)();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return '## $version${unreleased ? '' : ' - $date'}\n\n$body';
  }

  Future<String> _git(List<String> args) async {
    final r = await Process.run('git', args, workingDirectory: repoPath);
    if (r.exitCode != 0) {
      throw Exception('git ${args.first} failed: ${r.stderr}'.trim());
    }
    return r.stdout as String;
  }

  /// Default tag pattern for [package] (a path), or `v*` for the workspace.
  static String defaultPattern(String? package) =>
      package == null ? 'v*' : '${p.basename(package)}-v*';
}
