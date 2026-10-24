import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_scripts/src/models/package_info.dart';
import 'package:yaml/yaml.dart';

/// Scans a workspace for packages and returns their metadata.
class PackageScanner() {
  /// Finds all packages in the workspace rooted at [rootPath].
  ///
  /// Recursively searches for `pubspec.yaml` files, skipping
  /// build directories, hidden directories, and the root pubspec.
  ///
  /// Callers that only need to look up a single package (e.g.
  /// [findPackage]) should use [_scanLazy] directly instead, so that
  /// `pubspec.yaml` parsing can stop as soon as a match is found rather
  /// than eagerly parsing every package in the workspace first.
  static List<PackageInfo> scan(String rootPath) =>
      _scanLazy(rootPath).toList();

  /// Finds a specific package by [name] in the workspace at [rootPath].
  ///
  /// Returns `null` if no matching package is found. Iterates lazily via
  /// [_scanLazy] so it stops walking/parsing the workspace as soon as a
  /// match is found, instead of materializing every package first.
  static PackageInfo? findPackage(String rootPath, String name) {
    for (final pkg in _scanLazy(rootPath)) {
      if (pkg.name == name) return pkg;
    }
    return null;
  }

  /// Lazily walks [rootPath] for `pubspec.yaml` files, yielding one
  /// [PackageInfo] per discovered package as it is parsed.
  ///
  /// This is a generator (`sync*`/`yield`) rather than a function that
  /// builds and returns a `List`: it lets single-match consumers (like
  /// [findPackage]) short-circuit without parsing YAML for every remaining
  /// package. Note that, like all `sync*`-backed [Iterable] instances,
  /// re-iterating the returned value re-runs the walk/parse from scratch —
  /// callers that need the same data more than once (e.g. [scan]) must
  /// materialize it with `.toList()` first.
  static Iterable<PackageInfo> _scanLazy(String rootPath) sync* {
    final root = Directory(rootPath);

    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('pubspec.yaml')) continue;

      final packageDir = p.dirname(entity.path);
      if (packageDir == rootPath) continue;

      final relativePath = p.relative(entity.path, from: rootPath);
      if (_shouldSkip(relativePath)) continue;

      final info = _parsePackage(entity, packageDir);
      if (info != null) {
        yield info;
      }
    }
  }

  static PackageInfo? _parsePackage(File pubspecFile, String packageDir) {
    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) return null;

      final name = yaml['name'] as String? ?? p.basename(packageDir);
      final version = (yaml['version'] as String?) ?? '0.0.0';

      final deps = yaml['dependencies'];
      final devDeps = yaml['dev_dependencies'];

      final depNames = deps is YamlMap
          ? deps.keys.cast<String>().toList()
          : <String>[];
      final devDepNames = devDeps is YamlMap
          ? devDeps.keys.cast<String>().toList()
          : <String>[];

      final isFlutter =
          deps is YamlMap &&
          deps.containsKey('flutter') &&
          deps['flutter'] is YamlMap &&
          (deps['flutter'] as YamlMap).containsKey('sdk');

      final hasTests = Directory(p.join(packageDir, 'test')).existsSync();

      return PackageInfo(
        name: name,
        path: packageDir,
        version: version,
        dependencies: depNames,
        devDependencies: devDepNames,
        isFlutter: isFlutter,
        hasTests: hasTests,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _shouldSkip(String relativePath) {
    final parts = p.split(relativePath);
    for (final part in parts) {
      if (part.startsWith('.')) return true;
      if (part == 'build') return true;
      if (part == '.dart_tool') return true;
    }
    return false;
  }
}
