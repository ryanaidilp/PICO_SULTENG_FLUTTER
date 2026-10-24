import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_prepare/src/build_prepare_config.dart';
import 'package:build_prepare/src/build_prepare_state.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// The mode for dependency swapping.
enum SwapMode() {
  /// Use debug dependencies (swap release -> debug).
  debug,

  /// Use release dependencies (swap debug -> release).
  release,
}

/// A record of a single dependency swap that was performed.
class const SwapResult({
  /// The path to the modified pubspec.yaml.
  required final String pubspecPath,

  /// The dependency that was removed.
  required final String from,

  /// The dependency that was added.
  required final String to,
}) {
  /// Creates a new [SwapResult].
  this;

  @override
  String toString() => '$pubspecPath: $from -> $to';
}

/// A record of a dart import rewrite that was performed.
class const DartImportRewriteResult({
  /// The path to the modified dart file.
  required final String filePath,

  /// The package name that was replaced.
  required final String from,

  /// The package name that was inserted.
  required final String to,

  /// File content before the rewrite. Populated when the caller asks
  /// `rewriteDartImports` to track originals (used for `--restore`).
  final String? originalContent,
}) {
  /// Creates a new [DartImportRewriteResult].
  this;

  @override
  String toString() => '$filePath: $from -> $to';
}

/// Command that swaps debug/release dependencies in pubspec.yaml files.
///
/// Two independent axes (ADR-035 and its amendment):
/// - the build's **flavor** swaps `mappings`: flavors in `internal_flavors`
///   keep the debug packages, every other flavor gets the noop twins;
/// - the build's **mode** swaps `debug_build_only`: `--mode release|profile`
///   gets the noop twins for every flavor, `--mode debug` restores them.
///   Without `--mode` they are left as they are, unless a `debug`/`release`
///   alias is given, which sets both axes.
///
/// Usage:
/// ```bash
/// dart run monorepo_toolkit build-prepare --flavor production --mode release
/// dart run monorepo_toolkit build-prepare --check-leaks --flavor alpha --mode release
/// dart run monorepo_toolkit build-prepare --restore
/// dart run monorepo_toolkit build-prepare release   # alias: every noop twin
/// dart run monorepo_toolkit build-prepare debug     # alias: every debug package
/// ```
class BuildPrepareCommand() extends Command<int> {
  /// Creates a new [BuildPrepareCommand].
  this {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to the build_prepare.yaml config file.',
        defaultsTo: 'build_prepare.yaml',
      )
      ..addOption(
        'flavor',
        abbr: 'f',
        help:
            'The build flavor. Without a mode, flavors in `internal_flavors` '
            'keep the debug packages and every other flavor gets the noop '
            'twins. Also filters mappings that declare `flavors`.',
      )
      ..addOption(
        'mode',
        abbr: 'm',
        allowed: ['debug', 'profile', 'release'],
        help:
            'The build mode. release and profile swap the `debug_build_only` '
            'mappings to their noop twins for every flavor; debug restores '
            'them. Omitted: they are left as they are. With --check-leaks the '
            'default is release.',
      )
      ..addFlag(
        'check-leaks',
        help:
            'After a build: fail if a mapped debug or `debug_only` package is '
            'resolved for the app (skipped for internal flavors), or a '
            '`debug_build_only` package is (skipped for --mode debug).',
        negatable: false,
      )
      ..addFlag(
        'restore',
        abbr: 'r',
        help:
            'Revert the most recent swap using `.build_prepare.state.json`. '
            'Mode arg (debug/release) is ignored.',
        negatable: false,
      );
  }

  @override
  String get name => 'build-prepare';

  @override
  String get description =>
      'Swap debug/release dependencies for build preparation.';

  @override
  Future<int> run() async {
    final restore = argResults!['restore'] as bool;
    final rootPath = MonorepoFinder.findRoot();

    if (rootPath == null) {
      stderr.writeln('Error: Could not find workspace root.');
      return 1;
    }

    if (restore) return await _runRestore(rootPath);

    final configPath = argResults!['config'] as String;
    final flavor = argResults!['flavor'] as String?;
    final buildModeArg = argResults!['mode'] as String?;
    final args = argResults!.rest;
    final checkLeaks = argResults!['check-leaks'] as bool;

    if (args.isEmpty && flavor == null && buildModeArg == null && !checkLeaks) {
      stderr.writeln(
        'Error: Pass --flavor <flavor> and/or --mode <mode>, or an alias: '
        'debug|release',
      );
      stderr.writeln(
        'Usage: dart run monorepo_toolkit build-prepare --flavor <flavor> '
        '--mode release',
      );
      return 1;
    }

    final fullConfigPath = p.join(rootPath, configPath);
    final config = BuildPrepareConfig.fromYamlFile(fullConfigPath);

    if (config == null) {
      stderr.writeln('Error: Could not load config from $fullConfigPath');
      return 1;
    }

    if (checkLeaks) {
      return _runLeakCheck(rootPath, config, flavor, buildModeArg ?? 'release');
    }

    // Flavor axis: `mappings`. Null when only --mode was passed.
    final SwapMode? mode;
    if (args.isEmpty && flavor == null) {
      mode = null;
    } else if (args.isEmpty) {
      final internal = config.isInternalFlavor(flavor!);
      mode = internal ? SwapMode.debug : SwapMode.release;
      stdout.writeln(
        internal
            ? 'Flavor "$flavor" is internal: keeping debug tooling.'
            : 'Flavor "$flavor" is not in internal_flavors: '
                  'swapping debug tooling to noop.',
      );
    } else {
      switch (args.first) {
        case 'debug':
          mode = SwapMode.debug;
        case 'release':
          mode = SwapMode.release;
        default:
          stderr.writeln(
            'Error: Unknown mode "${args.first}". Use debug or release, '
            'or pass --flavor.',
          );
          return 1;
      }
    }

    // Build-mode axis: `debug_build_only`. An alias sets both axes.
    final buildMode = switch (buildModeArg) {
      'debug' => SwapMode.debug,
      'release' || 'profile' => SwapMode.release,
      _ => args.isEmpty ? null : mode,
    };

    final pairs = [
      if (mode != null)
        for (final m in config.mappings)
          if (m.appliesToFlavor(flavor)) _pairFor(m, mode),
      if (buildMode != null)
        for (final m in config.debugBuildOnly) _pairFor(m, buildMode),
    ];

    if (pairs.isEmpty) {
      stdout.writeln(
        flavor == null
            ? 'No mappings configured.'
            : 'No mappings apply to flavor "$flavor".',
      );
      return 0;
    }

    // Determine target pubspec.yaml files
    final targetPubspecs = <String>[];
    if (config.targetPaths.isNotEmpty) {
      for (final targetPath in config.targetPaths) {
        final pubspecPath = p.join(rootPath, targetPath, 'pubspec.yaml');
        if (File(pubspecPath).existsSync()) {
          targetPubspecs.add(pubspecPath);
        } else {
          stderr.writeln('Warning: pubspec.yaml not found at $pubspecPath');
        }
      }
    } else {
      // Scan all packages in workspace
      final packages = PackageScanner.scan(rootPath);
      for (final pkg in packages) {
        targetPubspecs.add(p.join(pkg.path, 'pubspec.yaml'));
      }
    }

    // Everything goes back to debug: a release swap's snapshot is the exact
    // inverse, so restore it (key order, noop entries, comments) instead of
    // re-deriving by swap. Not when the build-mode list is left as it is: the
    // snapshot would restore it too.
    final allToDebug =
        pairs.every((pair) => !pair.toNoop) &&
        (buildMode != null || config.debugBuildOnly.isEmpty);
    if (allToDebug && _restoreUneditedFromState(rootPath)) {
      return 0;
    }

    final results = <SwapResult>[];
    final backups = <FileBackup>[];
    final backedUpPaths = <String>{};

    for (final pubspecPath in targetPubspecs) {
      final pubspecFile = File(pubspecPath);
      final originalContent = pubspecFile.readAsStringSync();
      var content = originalContent;
      var modified = false;

      for (final (:fromDep, :toDep, :toNoop) in pairs) {
        final result = swapDependency(
          pubspecContent: content,
          fromDep: fromDep,
          toDep: toDep,
          // Debug keeps a noop entry the bricks added; only release drops
          // the debug dep when both are present.
          dropFromWhenToPresent: toNoop,
        );

        if (result != null) {
          content = result;
          modified = true;
          results.add(
            SwapResult(
              pubspecPath: p.relative(pubspecPath, from: rootPath),
              from: fromDep,
              to: toDep,
            ),
          );
        }
      }

      if (modified) {
        final relPath = p.relative(pubspecPath, from: rootPath);
        if (backedUpPaths.add(relPath)) {
          backups.add(FileBackup(path: relPath, content: originalContent));
        }
        pubspecFile.writeAsStringSync(content);
      }
    }

    if (results.isEmpty) {
      stdout.writeln('No dependencies were swapped.');
      return 0;
    }

    stdout.writeln('Swapped ${results.length} dependency(ies):');
    for (final result in results) {
      stdout.writeln('  ${result.pubspecPath}: ${result.from} -> ${result.to}');
    }

    final missingMirrors = <String>[];

    // Rewrite dart imports in target paths
    if (config.targetPaths.isNotEmpty) {
      final importResults = <DartImportRewriteResult>[];

      for (final targetPath in config.targetPaths) {
        final targetDir = Directory(p.join(rootPath, targetPath));
        if (!targetDir.existsSync()) continue;

        for (final (:fromDep, :toDep, toNoop: _) in pairs) {
          final rewrites = rewriteDartImports(
            targetDir: targetDir,
            fromDep: fromDep,
            toDep: toDep,
            rootPath: rootPath,
            trackOriginal: true,
          );
          importResults.addAll(rewrites);
          missingMirrors.addAll(
            findMissingMirrors(
              targetDir: targetDir,
              toDep: toDep,
              rewrites: rewrites,
              rootPath: rootPath,
            ),
          );
          for (final r in rewrites) {
            if (r.originalContent == null) continue;
            if (backedUpPaths.add(r.filePath)) {
              backups.add(
                FileBackup(path: r.filePath, content: r.originalContent!),
              );
            }
          }
        }
      }

      if (importResults.isNotEmpty) {
        stdout.writeln(
          'Rewrote dart imports in ${importResults.length} file(s):',
        );
        for (final result in importResults) {
          stdout.writeln(
            '  ${result.filePath}: ${result.from} -> ${result.to}',
          );
        }
      }
    }

    if (backups.isNotEmpty) {
      // An earlier swap that was not restored keeps its original content, so
      // --restore still goes back to the pre-build files (e.g. a build-mode
      // swap followed by a flavor swap).
      final prior = {
        for (final b
            in BuildPrepareState.load(rootPath)?.files ?? const <FileBackup>[])
          b.path: b,
      };
      final current = {for (final b in backups) b.path};
      // Record post-swap content so `debug` can detect later edits.
      final files = [
        for (final b in backups)
          FileBackup(
            path: b.path,
            content: prior[b.path]?.content ?? b.content,
            swapped: File(p.join(rootPath, b.path)).readAsStringSync(),
          ),
        for (final b in prior.values)
          if (!current.contains(b.path)) b,
      ];
      BuildPrepareState.save(rootPath, BuildPrepareState(files: files));
      stdout.writeln(
        'Wrote ${BuildPrepareState.stateFileName} '
        '(${backups.length} file(s) snapshotted). '
        "Run 'build-prepare --restore' to revert.",
      );
    }

    // After the state save so --restore still reverts the swap.
    if (missingMirrors.isNotEmpty) {
      stderr.writeln('Error: rewritten imports point to missing libraries:');
      for (final miss in missingMirrors) {
        stderr.writeln('  $miss');
      }
      stderr.writeln(
        'Add the same file to the swapped package (a noop must mirror every '
        'library of the package it replaces).',
      );
      return 1;
    }

    return 0;
  }

  /// Swaps a dependency entry in pubspec.yaml content from [fromDep] to
  /// [toDep], operating on the parsed `dependencies:` map rather than raw
  /// string replacement.
  ///
  /// This is prefix-collision safe: swapping `app_debugger` will never touch
  /// the sibling keys `app_debugger_network`, `app_debugger_storage`, etc.,
  /// because the swap is keyed on the exact dependency name.
  ///
  /// Behavior:
  /// - If `dependencies[fromDep]` does not exist → returns `null` (no-op).
  /// - The new `path:` is derived from [fromDep]'s path by replacing only the
  ///   trailing path segment that equals [fromDep] with [toDep]
  ///   (e.g. `../../features/app_blackbox/app_blackbox` →
  ///   `../../features/app_blackbox/app_blackbox_noop`). Parent/group dirs are
  ///   never touched. If the leaf segment is not exactly [fromDep], it falls
  ///   back to `<parent-of-leaf>/<toDep>`.
  /// - If `dependencies[toDep]` already exists (mixed state) → [fromDep] is
  ///   simply removed (no duplicate key is inserted).
  /// - Otherwise → [fromDep] is removed and [toDep] is inserted with the
  ///   computed path.
  ///
  /// The transformation is idempotent and no-op-safe. Returns the modified
  /// content, or `null` if no change was made.
  ///
  /// Only the top-level `dependencies:` map is scanned — swap targets under
  /// `dev_dependencies:`/`dependency_overrides:` are intentionally not touched
  /// (no current mapping lives there). The path-leaf swap assumes path deps;
  /// hosted/version swap targets are not a supported mapping shape.
  static String? swapDependency({
    required String pubspecContent,
    required String fromDep,
    required String toDep,
    bool dropFromWhenToPresent = true,
  }) {
    final doc = loadYaml(pubspecContent);
    if (doc is! YamlMap) return null;

    final deps = doc['dependencies'];
    if (deps is! YamlMap || !deps.containsKey(fromDep)) return null;

    final editor = YamlEditor(pubspecContent);

    // mixed state: toDep already present → just drop fromDep, no duplicate.
    if (deps.containsKey(toDep)) {
      if (!dropFromWhenToPresent) return null;
      editor.remove(['dependencies', fromDep]);
      return editor.toString();
    }

    final fromValue = deps[fromDep];
    final newPath = _swapPathLeaf(fromValue, fromDep, toDep);

    editor
      ..remove(['dependencies', fromDep])
      ..update(['dependencies', toDep], {'path': newPath});

    return editor.toString();
  }

  /// Computes [toDep]'s path from [fromDep]'s dependency [fromValue].
  ///
  /// Replaces only the trailing path segment equal to [fromDep] with [toDep].
  /// Falls back to `<parent-of-leaf>/<toDep>` when the leaf differs, and to a
  /// bare `<toDep>` when no usable path is present.
  static String _swapPathLeaf(Object? fromValue, String fromDep, String toDep) {
    final fromPath = (fromValue is YamlMap ? fromValue['path'] : null);
    if (fromPath is! String || fromPath.isEmpty) return toDep;

    // Replace only the trailing segment. When the leaf equals fromDep this is
    // an exact leaf swap; otherwise it resolves to `<parent-of-leaf>/<toDep>`.
    final segments = p.split(fromPath);
    segments[segments.length - 1] = toDep;
    return p.joinAll(segments);
  }

  /// Rewrites `package:<fromDep>/...` import URIs in all `.dart` files under
  /// `lib/` and `test/` within [targetDir].
  ///
  /// Replaces both:
  /// - `package:<fromDep>/` → `package:<toDep>/` (all import paths)
  /// - `/<fromDep>.dart` → `/<toDep>.dart` (barrel file references)
  ///
  /// Only writes files whose content actually changed. Returns one
  /// [DartImportRewriteResult] per modified file.
  static List<DartImportRewriteResult> rewriteDartImports({
    required Directory targetDir,
    required String fromDep,
    required String toDep,
    required String rootPath,
    bool trackOriginal = false,
  }) {
    final results = <DartImportRewriteResult>[];

    for (final subDir in ['lib', 'test']) {
      final dir = Directory(p.join(targetDir.path, subDir));
      if (!dir.existsSync()) continue;

      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final original = file.readAsStringSync();
        var updated = original;

        // Replace package URI prefix: package:fromDep/ -> package:toDep/
        updated = updated.replaceAll('package:$fromDep/', 'package:$toDep/');

        // Replace barrel file suffix: /fromDep.dart -> /toDep.dart
        updated = updated.replaceAll('/$fromDep.dart', '/$toDep.dart');

        if (updated != original) {
          file.writeAsStringSync(updated);
          results.add(
            DartImportRewriteResult(
              filePath: p.relative(file.path, from: rootPath),
              from: fromDep,
              to: toDep,
              originalContent: trackOriginal ? original : null,
            ),
          );
        }
      }
    }

    return results;
  }

  /// Returns one message per `package:<toDep>/<path>` URI in the [rewrites]
  /// files whose `lib/<path>` does not exist in [toDep], resolved from the
  /// `path:` entry in [targetDir]'s (already swapped) pubspec.yaml.
  ///
  /// Returns nothing when [toDep] cannot be resolved to a local path.
  static List<String> findMissingMirrors({
    required Directory targetDir,
    required String toDep,
    required List<DartImportRewriteResult> rewrites,
    required String rootPath,
  }) {
    if (rewrites.isEmpty) return const [];
    final pubspec = File(p.join(targetDir.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return const [];
    final doc = loadYaml(pubspec.readAsStringSync());
    final deps = doc is YamlMap ? doc['dependencies'] : null;
    final dep = deps is YamlMap ? deps[toDep] : null;
    final path = dep is YamlMap ? dep['path'] : null;
    if (path is! String) return const [];

    final libDir = p.join(targetDir.path, path, 'lib');
    final uri = RegExp('package:${RegExp.escape(toDep)}/([^\'"]+)');
    final misses = <String>[];
    for (final r in rewrites) {
      final content = File(p.join(rootPath, r.filePath)).readAsStringSync();
      for (final m in uri.allMatches(content)) {
        final lib = m.group(1)!;
        if (!File(p.join(libDir, lib)).existsSync()) {
          misses.add('${r.filePath}: package:$toDep/$lib (missing lib/$lib)');
        }
      }
    }
    return misses.toSet().toList();
  }

  /// Restores snapshotted files whose content still equals the post-swap
  /// snapshot. Returns true when the state was fully consumed. When any file
  /// was edited since the swap, it is left untouched with a warning and the
  /// caller falls back to the in-place swap (state is dropped either way).
  bool _restoreUneditedFromState(String rootPath) {
    final state = BuildPrepareState.load(rootPath);
    if (state == null) return false;

    var restored = 0;
    final edited = <String>[];
    for (final backup in state.files) {
      final file = File(p.join(rootPath, backup.path));
      if (backup.swapped == null ||
          !file.existsSync() ||
          file.readAsStringSync() != backup.swapped) {
        edited.add(backup.path);
        continue;
      }
      file.writeAsStringSync(backup.content);
      restored++;
    }

    BuildPrepareState.delete(rootPath);
    stdout.writeln('Restored $restored file(s) from state.');
    if (edited.isEmpty) return true;

    stderr.writeln(
      'Warning: changed since the release swap, not overwritten; swapping '
      'in place instead: ${edited.join(', ')}',
    );
    return false;
  }

  int _runLeakCheck(
    String rootPath,
    BuildPrepareConfig config,
    String? flavor,
    String buildMode,
  ) {
    final internal = flavor != null && config.isInternalFlavor(flavor);
    // Hosted packages such as marionette_flutter stay in the workspace-wide
    // pubspec.lock while app_marionette is a workspace member, so these are
    // checked in the app's graph and plugins only.
    final buildModeForbidden = buildMode == 'debug'
        ? const <String>{}
        : {
            for (final m in config.debugBuildOnly) m.debug,
            ...config.debugBuildOnlyPackages,
          };
    final forbidden = {
      if (!internal) ...{
        for (final m in config.mappings)
          if (m.appliesToFlavor(flavor)) m.debug,
        ...config.debugOnly,
      },
      ...buildModeForbidden,
    };

    if (forbidden.isEmpty) {
      stdout.writeln(
        internal
            ? 'Flavor "$flavor" is internal: debug tooling is expected, '
                  'leak check skipped.'
            : 'Nothing to guard for this flavor and mode, leak check skipped.',
      );
      return 0;
    }

    final leaks = findLeaks(
      rootPath: rootPath,
      targetPaths: config.targetPaths,
      forbidden: forbidden,
      notInLock: buildModeForbidden,
    );

    if (leaks == null) {
      stderr.writeln(
        'Error: nothing to check. Run --check-leaks after `flutter build` '
        '(needs .dart_tool/package_graph.json, pubspec.lock or '
        '.flutter-plugins-dependencies).',
      );
      return 1;
    }
    if (leaks.isEmpty) {
      stdout.writeln('Leak check passed: no debug-only package resolved.');
      return 0;
    }

    stderr.writeln('Leak check FAILED: debug-only packages in this build:');
    for (final leak in leaks) {
      stderr.writeln('  $leak');
    }
    stderr.writeln(
      "Run 'build-prepare --flavor <flavor> --mode <mode>' before the build, "
      'or remove the direct dependency.',
    );
    return 1;
  }

  /// Returns where each [forbidden] package resolves for the apps in
  /// [targetPaths], or `null` when no resolution output exists to check.
  ///
  /// Reads the app's dependency closure from `.dart_tool/package_graph.json`
  /// (workspace members never appear in `pubspec.lock`), the root
  /// `pubspec.lock`, and each app's `.flutter-plugins-dependencies` (native
  /// plugins; dev-only plugins are not linked and are ignored). Names in
  /// [notInLock] are not looked up in `pubspec.lock`, which is shared by the
  /// whole workspace.
  static List<String>? findLeaks({
    required String rootPath,
    required List<String> targetPaths,
    required Set<String> forbidden,
    Set<String> notInLock = const {},
  }) {
    final leaks = <String>[];
    var checked = false;

    final lock = File(p.join(rootPath, 'pubspec.lock'));
    if (lock.existsSync()) {
      checked = true;
      final packages = (loadYaml(lock.readAsStringSync()) as Map?)?['packages'];
      if (packages is Map) {
        leaks.addAll(
          packages.keys
              .where((n) => forbidden.contains(n) && !notInLock.contains(n))
              .map((n) => 'pubspec.lock: $n'),
        );
      }
    }

    final graphFile = File(
      p.join(rootPath, '.dart_tool', 'package_graph.json'),
    );
    final graph = <String, List<String>>{};
    if (graphFile.existsSync()) {
      checked = true;
      final json = jsonDecode(graphFile.readAsStringSync()) as Map;
      for (final pkg
          in (json['packages'] as List).cast<Map<String, dynamic>>()) {
        graph[pkg['name'] as String] =
            ((pkg['dependencies'] as List?) ?? const []).cast<String>();
      }
    }

    for (final target in targetPaths) {
      final pubspec = File(p.join(rootPath, target, 'pubspec.yaml'));
      final pubspecYaml = pubspec.existsSync()
          ? loadYaml(pubspec.readAsStringSync())
          : null;
      final appName = pubspecYaml is Map ? pubspecYaml['name'] : null;
      if (appName is String && graph.containsKey(appName)) {
        final seen = <String>{};
        final queue = [appName];
        while (queue.isNotEmpty) {
          final name = queue.removeLast();
          if (!seen.add(name)) continue;
          queue.addAll(graph[name] ?? const []);
        }
        leaks.addAll(
          seen.where(forbidden.contains).map((n) => '$target dependency: $n'),
        );
      }

      final plugins = File(
        p.join(rootPath, target, '.flutter-plugins-dependencies'),
      );
      if (!plugins.existsSync()) continue;
      checked = true;
      final json = jsonDecode(plugins.readAsStringSync()) as Map;
      final names = <String>{
        for (final platform in ((json['plugins'] as Map?) ?? {}).values)
          for (final plugin in (platform as List).cast<Map<String, dynamic>>())
            if (plugin['dev_dependency'] != true) plugin['name'] as String,
      };
      leaks.addAll(
        names.where(forbidden.contains).map((n) => '$target plugin: $n'),
      );
    }

    return checked ? leaks : null;
  }

  Future<int> _runRestore(String rootPath) async {
    final state = BuildPrepareState.load(rootPath);
    if (state == null) {
      stdout.writeln('No build_prepare state found — nothing to restore.');
      return 0;
    }

    for (final backup in state.files) {
      final file = File(p.join(rootPath, backup.path));
      file.writeAsStringSync(backup.content);
    }

    BuildPrepareState.delete(rootPath);

    stdout.writeln('Restored ${state.files.length} file(s) from state.');
    return 0;
  }
}

/// One dependency swap, in the direction the flavor or build mode chose.
typedef _SwapPair = ({String fromDep, String toDep, bool toNoop});

_SwapPair _pairFor(DependencyMapping m, SwapMode mode) =>
    mode == SwapMode.release
    ? (fromDep: m.debug, toDep: m.release, toNoop: true)
    : (fromDep: m.release, toDep: m.debug, toNoop: false);
