import 'package:host_registry_generator/src/models/di_resolution_exception.dart';
import 'package:host_registry_generator/src/models/package_manifest.dart';
import 'package:host_registry_generator/src/models/test_prerequisite_declaration.dart';
import 'package:host_registry_generator/src/services/topological_order.dart';

/// Resolves every package's declared `test_prerequisites` into the order
/// the composition-root harness installs them.
///
/// Same ordering rules as `DiModuleResolver`: package-level `depends_on`
/// first, then each package's own declaration order, then package name
/// (alphabetical). Unlike `di_modules`, a `depends_on` naming a package
/// that declares no prerequisites is ignored, not an error: that brick may
/// simply not be installed.
class const TestPrerequisiteResolver._() {
  /// Resolves [manifests] into an ordered prerequisite list.
  ///
  /// Throws [DiModuleCycleException] if the `depends_on` edges form a cycle.
  static List<TestPrerequisiteDeclaration> resolve(
    List<PackageManifest> manifests,
  ) {
    final byId = <String, TestPrerequisiteDeclaration>{};
    final indexById = <String, int>{};
    final idsByPackage = <String, List<String>>{};
    for (final manifest in manifests) {
      for (final (i, decl) in manifest.testPrerequisites.indexed) {
        final id = '${decl.packageName}::${decl.className}';
        byId[id] = decl;
        indexById[id] = i;
        (idsByPackage[decl.packageName] ??= []).add(id);
      }
    }

    final edges = <String, Set<String>>{for (final id in byId.keys) id: {}};
    for (final ids in idsByPackage.values) {
      for (var i = 0; i < ids.length - 1; i++) {
        edges[ids[i]]!.add(ids[i + 1]);
      }
    }
    for (final MapEntry(key: id, value: decl) in byId.entries) {
      for (final dep in decl.dependsOn) {
        for (final depId in idsByPackage[dep] ?? const <String>[]) {
          if (depId != id) edges[depId]!.add(id);
        }
      }
    }

    return topologicalOrder(
      ids: byId.keys,
      edges: edges,
      compare: (a, b) {
        final byPackage = byId[a]!.packageName.compareTo(byId[b]!.packageName);
        return byPackage != 0
            ? byPackage
            : indexById[a]!.compareTo(indexById[b]!);
      },
    ).map((id) => byId[id]!).toList(growable: false);
  }
}
