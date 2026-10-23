import 'dart:io';

import 'package:shared_scripts/src/shell_runner.dart';

/// Detects which files changed between the current branch and a base branch.
///
/// Handles both GitHub Actions (`GITHUB_BASE_REF`) and GitLab CI
/// (`CI_MERGE_REQUEST_TARGET_BRANCH_NAME`) environments automatically.
class GitChanges() {
  /// Returns added/copied/modified/renamed files in the current branch
  /// relative to [baseBranch].
  ///
  /// Resolution order for the base branch:
  /// 1. Explicit [baseBranch] argument
  /// 2. `GITHUB_BASE_REF` env var (GitHub Actions)
  /// 3. `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` env var (GitLab CI)
  /// 4. `develop` if that local branch exists, otherwise `main`
  ///
  /// GitLab CI shallow-clones only the MR branch by default, so when running
  /// under GitLab the target branch is fetched from origin before diffing.
  static Future<List<String>> getChangedFiles({
    String? baseBranch,
    String? rootPath,
  }) async {
    final gitlabBase =
        Platform.environment['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'];

    final base =
        baseBranch ??
        Platform.environment['GITHUB_BASE_REF'] ??
        gitlabBase ??
        await _detectBaseBranch(rootPath);

    // GitLab CI shallow-clones only the MR branch; the target branch ref is
    // not present until explicitly fetched.
    if (baseBranch == null && gitlabBase != null) {
      await ShellRunner.run(
        'git fetch origin $base',
        workingDirectory: rootPath,
      );
    }

    final result = await ShellRunner.run(
      'git diff --name-only --diff-filter=ACMR origin/$base...HEAD',
      workingDirectory: rootPath,
    );
    if (result.exitCode == 0) return _parseLines(result.stdout.toString());

    // Fallback: without 'origin/' prefix for local branches.
    final fallback = await ShellRunner.run(
      'git diff --name-only --diff-filter=ACMR $base',
      workingDirectory: rootPath,
    );
    if (fallback.exitCode != 0) {
      throw StateError(
        'git diff failed (exit ${fallback.exitCode}): ${fallback.stderr}',
      );
    }
    return _parseLines(fallback.stdout.toString());
  }

  static Future<String> _detectBaseBranch(String? rootPath) async {
    final result = await ShellRunner.run(
      'git branch --list develop',
      workingDirectory: rootPath,
    );
    return result.stdout.toString().trim().isNotEmpty ? 'develop' : 'main';
  }

  static List<String> _parseLines(String output) => output
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}
