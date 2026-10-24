import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Directories to skip during package discovery.
const _skipDirs = <String>{
  '.dart_tool',
  '.git',
  '.idea',
  '.vscode',
  'build',
  'node_modules',
  '.fvm',
  '.pub-cache',
};

/// Result of checking a package for `resolution: workspace`.
class const ResolutionCheckResult({
  /// Relative path to the package.
  required final String packagePath,

  /// Whether the package has `resolution: workspace`.
  required final bool hasResolution,
}) {
  /// Creates a [ResolutionCheckResult].
  this;
}

/// Result of checking for duplicate dependency_overrides.
class const OverrideConflict({
  /// The dependency name that is overridden in multiple packages.
  required final String dependency,

  /// The packages that each override this dependency.
  required final List<String> packages,
}) {
  /// Creates an [OverrideConflict].
  this;
}

/// Service for managing workspace configuration in a monorepo.
class const WorkspaceService({
  /// Path to the monorepo root.
  required final String rootPath,
}) {
  /// Creates a new [WorkspaceService].
  this;

  /// Gets the path to the root pubspec.yaml.
  String get rootPubspecPath => path.join(rootPath, 'pubspec.yaml');

  /// Reads the workspace field from root pubspec.yaml.
  ///
  /// Returns the raw list of entries (which may be glob patterns or explicit
  /// paths depending on the workspace configuration).
  Future<List<String>> getRootWorkspaceEntries() async {
    final pubspecFile = File(rootPubspecPath);
    if (!pubspecFile.existsSync()) return [];

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;
    if (yaml == null) return [];

    final workspace = yaml['workspace'] as YamlList?;
    if (workspace == null) return [];

    return workspace.map((e) => e.toString()).toList();
  }

  /// Returns true if the workspace field contains glob patterns.
  ///
  /// Globs are detected by the presence of `*`, `?`, `[`, or `{` characters.
  Future<bool> workspaceUsesGlobs() async {
    final entries = await getRootWorkspaceEntries();
    return entries.any(
      (e) =>
          e.contains('*') ||
          e.contains('?') ||
          e.contains('[') ||
          e.contains('{'),
    );
  }

  /// Expands glob patterns from the workspace field and returns all matched
  /// package directories (relative to rootPath) that contain a pubspec.yaml.
  ///
  /// Only directories that have a `pubspec.yaml` file are included.
  Future<List<String>> expandGlobPatterns() async {
    final entries = await getRootWorkspaceEntries();
    final found = <String>{};

    for (final entry in entries) {
      // Append /pubspec.yaml to find packages matched by the glob
      final pubspecGlob = Glob('$entry/pubspec.yaml');

      await for (final entity in pubspecGlob.list(root: rootPath)) {
        final packageDir = entity.parent.path;
        final relative = path.relative(packageDir, from: rootPath);

        if (_shouldSkipPath(relative)) continue;
        found.add(relative);
      }
    }

    return found.toList()..sort();
  }

  /// Finds all Dart/Flutter packages in the monorepo by recursive scan.
  ///
  /// This is used during `setup` to build the initial glob patterns.
  ///
  /// Delegates the directory walk to [PackageScanner.scan] (shared with the
  /// other `devtools/scripts` CLIs) instead of re-implementing it, then
  /// re-applies this service's own `_shouldSkipPath` as a thin post-filter.
  /// That filter is a strict superset of [PackageScanner]'s built-in skip
  /// list (it also excludes `node_modules`), so results are unchanged from
  /// the previous hand-rolled walk.
  List<String> findAllPackages() {
    final packages = <String>{};

    try {
      for (final pkg in PackageScanner.scan(rootPath)) {
        final relativePath = path.relative(pkg.path, from: rootPath);

        // Skip if path contains excluded directories
        if (_shouldSkipPath(relativePath)) continue;

        packages.add(relativePath);
      }
    } catch (_) {
      // Ignore permission errors
    }

    return packages.toList()..sort();
  }

  /// Converts an explicit list of package paths to glob patterns.
  ///
  /// Groups packages by their top-level directory. If all packages under a
  /// top-level dir share the same depth, uses a single-level glob (`dir/*`).
  /// Otherwise uses a recursive glob (`dir/**`).
  List<String> convertToGlobPatterns(List<String> explicitPaths) {
    if (explicitPaths.isEmpty) return [];

    // Group by top-level segment
    final byTopLevel = <String, List<String>>{};
    for (final p in explicitPaths) {
      final segments = path.split(p);
      final topLevel = segments.first;
      byTopLevel.putIfAbsent(topLevel, () => []).add(p);
    }

    final globs = <String>[];
    for (final entry in byTopLevel.entries) {
      final topLevel = entry.key;
      final paths = entry.value;

      // Check if all are exactly one level deep
      final allSingleLevel = paths.every((p) => path.split(p).length == 2);

      if (allSingleLevel) {
        globs.add('$topLevel/*');
      } else {
        globs.add('$topLevel/**');
      }
    }

    return globs..sort();
  }

  /// Updates the workspace entries in root pubspec.yaml.
  Future<void> updateWorkspaceEntries(List<String> entries) async {
    final pubspecFile = File(rootPubspecPath);
    if (!pubspecFile.existsSync()) {
      throw StateError('Root pubspec.yaml does not exist at $rootPubspecPath');
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    final sorted = List<String>.from(entries)..sort();
    editor.update(['workspace'], sorted);

    await pubspecFile.writeAsString(editor.toString());
  }

  /// Ensures a package has `resolution: workspace` in its pubspec.yaml.
  ///
  /// Returns true if the file was modified, false if already configured.
  Future<bool> ensureResolutionWorkspace(String packagePath) async {
    final pubspecPath = path.join(rootPath, packagePath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      throw StateError('pubspec.yaml does not exist at $pubspecPath');
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml != null && yaml['resolution'] == 'workspace') {
      return false;
    }

    final editor = YamlEditor(content);
    editor.update(['resolution'], 'workspace');

    await pubspecFile.writeAsString(editor.toString());
    return true;
  }

  /// Checks if a package has `resolution: workspace`.
  Future<bool> hasResolutionWorkspace(String packagePath) async {
    final pubspecPath = path.join(rootPath, packagePath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) return false;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    return yaml != null && yaml['resolution'] == 'workspace';
  }

  /// Checks all glob-matched packages for `resolution: workspace`.
  ///
  /// Returns a list of [ResolutionCheckResult] for each package.
  Future<List<ResolutionCheckResult>> checkAllResolutions() async {
    final packages = await expandGlobPatterns();
    final results = <ResolutionCheckResult>[];

    for (final pkg in packages) {
      final hasResolution = await hasResolutionWorkspace(pkg);
      results.add(
        ResolutionCheckResult(packagePath: pkg, hasResolution: hasResolution),
      );
    }

    return results;
  }

  /// Detects duplicate `dependency_overrides` across all glob-matched packages.
  ///
  /// A conflict occurs when the same dependency is overridden in more than one
  /// package's pubspec.yaml. Returns a list of [OverrideConflict].
  Future<List<OverrideConflict>> detectOverrideConflicts() async {
    final packages = await expandGlobPatterns();

    // Map: dependency name -> list of packages overriding it
    final overridesByDep = <String, List<String>>{};

    for (final pkg in packages) {
      final pubspecPath = path.join(rootPath, pkg, 'pubspec.yaml');
      final pubspecFile = File(pubspecPath);
      if (!pubspecFile.existsSync()) continue;

      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) continue;

      final overrides = yaml['dependency_overrides'] as YamlMap?;
      if (overrides == null) continue;

      for (final dep in overrides.keys) {
        overridesByDep.putIfAbsent(dep.toString(), () => []).add(pkg);
      }
    }

    // Also check root pubspec for overrides (not a conflict with root,
    // but we want to see which packages duplicate root overrides)
    // For the purpose of this tool, conflicts are package-to-package only.

    return overridesByDep.entries
        .where((e) => e.value.length > 1)
        .map((e) => OverrideConflict(dependency: e.key, packages: e.value))
        .toList();
  }

  /// Checks if path contains any skip directories.
  bool _shouldSkipPath(String relativePath) {
    final segments = path.split(relativePath);
    for (final segment in segments) {
      if (_skipDirs.contains(segment) || segment.startsWith('.')) {
        return true;
      }
    }
    return false;
  }
}
