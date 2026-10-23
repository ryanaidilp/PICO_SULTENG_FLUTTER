import 'dart:io';

import 'package:host_registry_generator/src/models/host_registry_app_not_found_exception.dart';
import 'package:host_registry_generator/src/models/host_registry_generation_result.dart';
import 'package:host_registry_generator/src/models/host_registry_target_not_found_exception.dart';
import 'package:host_registry_generator/src/models/package_manifest.dart';
import 'package:host_registry_generator/src/models/resolved_module.dart';
import 'package:host_registry_generator/src/models/test_harness_generation_result.dart';
import 'package:host_registry_generator/src/services/di_module_resolver.dart';
import 'package:host_registry_generator/src/services/test_prerequisite_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Marker slot regenerated with one `import 'package:<pkg>/<pkg>.dart';`
/// line per package that declares at least one `di_modules` entry.
const featureImportsSlot = 'feature_imports';

/// Marker slot regenerated with one `ExternalModule(ClassName),` line per
/// resolved `scope: before` module, in registration order. Corresponds to
/// `externalPackageModulesBefore`.
const featureModulesBeforeSlot = 'feature_modules_before';

/// Marker slot regenerated with one `ExternalModule(ClassName),` line per
/// resolved `scope: after` module, in registration order. Corresponds to
/// `externalPackageModulesAfter`.
const featureModulesAfterSlot = 'feature_modules_after';

/// Marker slot in `composition_root_harness.dart` regenerated with one
/// import per distinct `test_prerequisites` import URI.
const testPrerequisiteImportsSlot = 'test_prerequisite_imports';

/// Marker slot in `composition_root_harness.dart` regenerated with one
/// `await <Class>().install();` per resolved prerequisite, each preceded by
/// its declared `reason:` as a `///` comment.
const testPrerequisitesSlot = 'test_prerequisites';

/// Where an app's harness lives, relative to `apps/<app>/`.
const testHarnessRelativePath = 'test/support/composition_root_harness.dart';

/// Written by [HostRegistryService.generateTestHarness] when the harness
/// does not exist yet; its two marker regions are then filled in.
const testHarnessSkeleton = '''
// Test prerequisites for the composition root (ADR-017).
//
// `dart run monorepo_toolkit generate test-harness` rewrites both
// `archipelago:test_prerequisite*` marker regions from each installed
// package's `archipelago: test_prerequisites` pubspec declaration. Never edit
// inside them: declare the prerequisite in the package that does the platform
// I/O and re-run the generator. Hand-written imports go above the markers,
// which is why `directives_ordering` is suppressed (and `unnecessary_ignore`
// for when they happen to sort).
// ignore_for_file: directives_ordering, unnecessary_ignore
import 'package:flutter_test/flutter_test.dart';

// archipelago:test_prerequisite_imports:start
// archipelago:test_prerequisite_imports:end

/// Installs the platform fakes every installed package needs before
/// `initializeInjector()` can run under `flutter test`, in resolved order.
///
/// Idempotent: safe to call from several test files in one process. Call it
/// from `setUpAll`, before `initializeInjector()`.
Future<void> installCompositionRootPrerequisites() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // archipelago:test_prerequisites:start
  // archipelago:test_prerequisites:end
}
''';

/// Scans a workspace for `archipelago:` `di_modules` manifests, resolves
/// them into a deterministic order, and regenerates the
/// [featureImportsSlot] / [featureModulesBeforeSlot] /
/// [featureModulesAfterSlot] marker regions of a target `injector.dart`.
class const HostRegistryService({
  /// Path to the monorepo workspace root.
  required final String rootPath,
}) {
  /// Creates a new [HostRegistryService] rooted at [rootPath].
  this;

  /// Scans every workspace package for an `archipelago:` manifest.
  ///
  /// When [restrictTo] is given, packages whose name is not in that set are
  /// skipped entirely — used by [generate] to scope the scan to the target
  /// app's dependency closure instead of the whole workspace. `null` (the
  /// default) scans everything, which is what [dependencyClosure] itself
  /// needs (it must see every package's `dependencies:` to walk the graph).
  ///
  /// Exposed separately from [generate] so callers (and tests) can inspect
  /// the manifest set — or feed it straight to [DiModuleResolver] — without
  /// requiring a target `injector.dart` file to exist.
  List<PackageManifest> scanManifests({Set<String>? restrictTo}) {
    final manifests = <PackageManifest>[];
    for (final pkg in PackageScanner.scan(rootPath)) {
      if (restrictTo != null && !restrictTo.contains(pkg.name)) continue;
      final pubspecFile = File(p.join(pkg.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) continue;
      manifests.add(
        PackageManifest.parse(
          packageName: pkg.name,
          pubspecContent: pubspecFile.readAsStringSync(),
        ),
      );
    }
    return manifests;
  }

  /// The transitive closure of [appPackageName]'s regular `dependencies:`
  /// (never `dev_dependencies:`) over [packages] — the set of workspace
  /// package names eligible to contribute a `di_modules` entry to
  /// [appPackageName]'s injector. Includes [appPackageName] itself.
  ///
  /// A dependency name with no matching entry in [packages] (an external
  /// pub package, e.g. `get_it` or `flutter_native_splash`) is a dead end:
  /// it is not added to the closure and its own dependencies are not
  /// walked, since it cannot declare an `archipelago:` manifest.
  static Set<String> dependencyClosure(
    String appPackageName,
    List<PackageInfo> packages,
  ) {
    final byName = {for (final pkg in packages) pkg.name: pkg};
    final closure = <String>{};
    final visited = <String>{};
    final queue = <String>[appPackageName];
    while (queue.isNotEmpty) {
      final name = queue.removeLast();
      if (!visited.add(name)) continue;
      final pkg = byName[name];
      if (pkg == null) continue;
      closure.add(name);
      queue.addAll(pkg.dependencies);
    }
    return closure;
  }

  /// Scans the workspace, resolves the registration order for the target
  /// app's dependency closure, and rewrites the marker regions of the
  /// `injector.dart` at [targetInjectorPath] — unless [write] is `false`,
  /// in which case the file is left untouched and only
  /// [HostRegistryGenerationResult.changed] reports whether it *would*
  /// have changed (used by `--check`).
  ///
  /// The app package is resolved from `<targetInjectorPath>/../../../`
  /// (`apps/<app>/`)'s own `pubspec.yaml`. Only packages in that app's
  /// transitive dependency closure (see [dependencyClosure]) are scanned
  /// for `di_modules` — a package the app does not depend on never
  /// contributes an `ExternalModule` to its injector, however scoping is
  /// itself the fix for the workspace-wide-scan bug this replaces.
  ///
  /// Idempotent: running this twice in a row with no manifest changes
  /// produces a byte-identical file on the second run — [generate]
  /// unconditionally regenerates each marked region from the resolved
  /// order rather than diffing/patching existing content, so a hand-edit
  /// (or stale content) inside the markers is normalized away rather than
  /// preserved.
  ///
  /// Throws [HostRegistryTargetNotFoundException] if [targetInjectorPath]
  /// does not exist, [HostRegistryAppNotFoundException] if its owning app
  /// package cannot be resolved, and `MarkerImbalanceException` (from
  /// `shared_scripts`) if it is missing one of the three required marker
  /// pairs. Throws `ManifestParseException`/`DiResolutionException`
  /// subtypes (see `package_manifest.dart` / `di_resolution_exception.dart`)
  /// if a manifest is malformed or the dependency graph is unresolvable.
  HostRegistryGenerationResult generate({
    required String targetInjectorPath,
    bool write = true,
    bool prune = false,
  }) {
    final targetFile = File(targetInjectorPath);
    if (!targetFile.existsSync()) {
      throw HostRegistryTargetNotFoundException(targetInjectorPath);
    }

    final closure = _appClosure(
      p.dirname(p.dirname(p.dirname(targetInjectorPath))),
    );
    final manifests = scanManifests(restrictTo: closure);

    final packagesWithModules = manifests
        .where((m) => m.diModules.isNotEmpty)
        .length;
    final totalModulesDeclared = manifests.fold<int>(
      0,
      (acc, m) => acc + m.diModules.length,
    );

    final resolution = DiModuleResolver.resolve(manifests);

    final original = targetFile.readAsStringSync();

    // Entries already in the file that no manifest in the app's closure
    // declares (a hand-added module, a pre-manifest project, a package left
    // in the noop state after build-prepare release) are kept at the end of
    // their region and reported, never dropped silently. [prune] opts out.
    final fileLines = original.split('\n');
    List<String> inner(String slot) {
      for (final b in MarkerScanner.scanBlocks(
        original,
        sourceLabel: targetInjectorPath,
      )) {
        if (b.slot == slot) return b.innerLines(fileLines);
      }
      return const [];
    }

    final resolvedNames = {for (final m in resolution.order) m.className};
    // Commented-out lines are ignored so they are never revived.
    Iterable<String> codeLines(String slot) =>
        inner(slot)
            .map((line) => line.trim())
            .where((line) => !line.startsWith('//'));
    // Commented-out lines stay in their region as comments, in file order.
    List<String> commentLines(String slot) => [
      for (final line in inner(slot).map((line) => line.trim()))
        if (line.startsWith('//')) line,
    ];
    List<String> unresolved(String slot) => prune
        ? const []
        : {
            for (final line in codeLines(slot))
              if (_moduleName(line) case final name?)
                if (!resolvedNames.contains(name)) name,
          }.toList();
    final preservedBefore = unresolved(featureModulesBeforeSlot);
    final preservedAfter = unresolved(featureModulesAfterSlot);
    final preserved = [...preservedBefore, ...preservedAfter];
    final keptImports = preserved.isEmpty
        ? const <String>[]
        : [
            for (final line in codeLines(featureImportsSlot))
              if (line.startsWith('import ')) line,
          ];

    var updated = MarkerScanner.replaceBlock(
      content: original,
      slot: featureImportsSlot,
      lines: [
        ..._buildImportLines(resolution.order, keptImports),
        ...commentLines(featureImportsSlot),
      ],
      sourceLabel: targetInjectorPath,
    );
    updated = MarkerScanner.replaceBlock(
      content: updated,
      slot: featureModulesBeforeSlot,
      lines: [
        ..._buildModuleLines(resolution.beforeModules),
        for (final name in preservedBefore) 'ExternalModule($name),',
        ...commentLines(featureModulesBeforeSlot),
      ],
      sourceLabel: targetInjectorPath,
    );
    updated = MarkerScanner.replaceBlock(
      content: updated,
      slot: featureModulesAfterSlot,
      lines: [
        ..._buildModuleLines(resolution.afterModules),
        for (final name in preservedAfter) 'ExternalModule($name),',
        ...commentLines(featureModulesAfterSlot),
      ],
      sourceLabel: targetInjectorPath,
    );

    final changed = updated != original;
    if (changed && write) targetFile.writeAsStringSync(updated);

    return HostRegistryGenerationResult(
      packagesScanned: closure.length,
      packagesWithModules: packagesWithModules,
      totalModulesDeclared: totalModulesDeclared,
      resolution: resolution,
      changed: changed,
      targetPath: targetInjectorPath,
      preservedModules: preserved,
    );
  }

  /// Regenerates the [testPrerequisiteImportsSlot] and
  /// [testPrerequisitesSlot] marker regions of the app's
  /// `test/support/composition_root_harness.dart` at [targetHarnessPath]
  /// from the `test_prerequisites` declared in the app's dependency
  /// closure, ordered by `TestPrerequisiteResolver`. A missing file is
  /// created from [testHarnessSkeleton]. With [write] `false` nothing is
  /// written and [TestHarnessGenerationResult.changed] reports drift.
  ///
  /// The app is `<targetHarnessPath>/../../../` (`apps/<app>/`). Throws
  /// [HostRegistryTargetNotFoundException] when that app has no
  /// `lib/di/injector.dart` (not a host app), plus the same exceptions as
  /// [generate] for a bad app, manifest, cycle or marker pair.
  TestHarnessGenerationResult generateTestHarness({
    required String targetHarnessPath,
    bool write = true,
  }) {
    final appDir = p.dirname(p.dirname(p.dirname(targetHarnessPath)));
    final injectorPath = p.join(appDir, 'lib', 'di', 'injector.dart');
    if (!File(injectorPath).existsSync()) {
      throw HostRegistryTargetNotFoundException(injectorPath);
    }

    final prerequisites = TestPrerequisiteResolver.resolve(
      scanManifests(restrictTo: _appClosure(appDir)),
    );

    final targetFile = File(targetHarnessPath);
    final exists = targetFile.existsSync();
    final original = exists
        ? targetFile.readAsStringSync()
        : testHarnessSkeleton;

    var updated = MarkerScanner.replaceBlock(
      content: original,
      slot: testPrerequisiteImportsSlot,
      lines: _sortedImportLines({
        for (final decl in prerequisites) "import '${decl.import}';",
      }),
      sourceLabel: targetHarnessPath,
    );
    updated = MarkerScanner.replaceBlock(
      content: updated,
      slot: testPrerequisitesSlot,
      lines: [
        for (final (i, decl) in prerequisites.indexed) ...[
          // `dart format` puts a blank line before a doc comment that follows
          // a statement; match it so `--check` sees no drift.
          if (i > 0) '',
          for (final line in _wrap(decl.reason, 74)) '/// $line',
          'await ${decl.className}().install();',
        ],
      ],
      sourceLabel: targetHarnessPath,
    );

    final changed = !exists || updated != original;
    if (changed && write) {
      targetFile.parent.createSync(recursive: true);
      targetFile.writeAsStringSync(updated);
    }

    return TestHarnessGenerationResult(
      prerequisites: prerequisites,
      changed: changed,
      targetPath: targetHarnessPath,
    );
  }

  /// [appDir]'s package name resolved against the workspace, then its
  /// dependency closure (see [dependencyClosure]).
  Set<String> _appClosure(String appDir) {
    final packages = PackageScanner.scan(rootPath);
    for (final pkg in packages) {
      if (p.equals(pkg.path, appDir)) {
        return dependencyClosure(pkg.name, packages);
      }
    }
    throw HostRegistryAppNotFoundException(appDir);
  }

  /// Greedy word wrap of [text] (whitespace collapsed) to [width] columns.
  static List<String> _wrap(String text, int width) {
    final lines = <String>[];
    var current = '';
    for (final word in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      if (current.isNotEmpty && current.length + 1 + word.length > width) {
        lines.add(current);
        current = word;
      } else {
        current = current.isEmpty ? word : '$current $word';
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  /// One `import '<uri>';` line per distinct import URI needed across
  /// [order], sorted alphabetically (matches `dart format`'s own
  /// import-sort order). Distinct-URI (not distinct-package) dedup means a
  /// package whose `di_modules` entries all share the default barrel
  /// import collapses to a single line, which is the common case; a
  /// package that overrides `import:` per-entry to point at more than one
  /// file still gets one line per distinct file.
  static List<String> _buildImportLines(
    List<ResolvedModule> order, [
    List<String> keptImports = const [],
  ]) => _sortedImportLines({
    for (final module in order) "import '${module.import}';",
    ...keptImports,
  });

  static List<String> _sortedImportLines(Set<String> imports) {
    final sorted = imports.toList()..sort();
    if (sorted.isEmpty) return const [];
    // Trailing blank line: `dart format` inserts one between a non-empty
    // import block and the `:end` marker comment, so emit it here or every
    // formatted project reports drift under `--check`.
    return [...sorted, ''];
  }

  static String? _moduleName(String line) =>
      RegExp(r'ExternalModule\(\s*(\w+)\s*\)').firstMatch(line)?.group(1);

  static List<String> _buildModuleLines(List<ResolvedModule> modules) => [
    for (final module in modules) 'ExternalModule(${module.className}),',
  ];
}
