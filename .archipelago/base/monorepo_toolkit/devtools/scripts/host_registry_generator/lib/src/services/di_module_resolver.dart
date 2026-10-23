import 'package:host_registry_generator/src/models/di_module_declaration.dart';
import 'package:host_registry_generator/src/models/di_module_resolution.dart';
import 'package:host_registry_generator/src/models/di_resolution_exception.dart';
import 'package:host_registry_generator/src/models/module_scope.dart';
import 'package:host_registry_generator/src/models/package_manifest.dart';
import 'package:host_registry_generator/src/models/resolved_module.dart';
import 'package:host_registry_generator/src/services/topological_order.dart';

/// Resolves every package's declared `di_modules` into a single,
/// deterministic registration order.
///
/// Pure logic — no file I/O — so it can be unit tested with synthetic
/// [PackageManifest] graphs.
///
/// ## Ordering rules
///
/// 1. **Explicit `depends_on`** (package-level): every module declared by
///    a package named in another module's `depends_on` is ordered strictly
///    before that module.
/// 2. **Implicit intra-package order**: a package's own `di_modules` list
///    is inherently sequential — module `i+1` is always ordered after
///    module `i` from the same package, in the unified order, regardless
///    of scope.
/// 3. **Deterministic tiebreak**: among modules with no ordering
///    constraint relative to each other, order by package name
///    (alphabetical), then by declaration order within that package's own
///    `di_modules` list.
///
/// The unified order is then split into `before`/`after` subsequences
/// (see [DiModuleResolution]), each preserving relative order from the
/// unified pass.
class const DiModuleResolver._() {
  /// Resolves [manifests] into a [DiModuleResolution].
  ///
  /// Throws [DiModuleDuplicateException] if a package declares the same
  /// class twice, [DiModuleUnknownDependencyException] if a `depends_on`
  /// entry names a package with no declared `di_modules`, and
  /// [DiModuleCycleException] if the `depends_on` edges form a cycle.
  static DiModuleResolution resolve(List<PackageManifest> manifests) {
    final modulesByPackage = <String, List<_Node>>{};
    final classOwners = <String, String>{};

    for (final manifest in manifests) {
      if (manifest.diModules.isEmpty) continue;

      final nodes = <_Node>[];
      final seenClasses = <String>{};
      for (var i = 0; i < manifest.diModules.length; i++) {
        final decl = manifest.diModules[i];
        if (!seenClasses.add(decl.className)) {
          throw DiModuleDuplicateException(
            packageName: manifest.packageName,
            className: decl.className,
          );
        }

        // Cross-package check: the same ExternalModule class declared by
        // two different packages (e.g. an impl/noop pair both still
        // manifesting after a build_prepare swap) resolves ambiguously —
        // catch it here rather than let two imports silently export the
        // same class name into the generated injector.dart.
        final existingOwner = classOwners[decl.className];
        if (existingOwner != null && existingOwner != manifest.packageName) {
          throw DiModuleCrossPackageDuplicateException(
            className: decl.className,
            firstPackageName: existingOwner,
            secondPackageName: manifest.packageName,
          );
        }
        classOwners[decl.className] = manifest.packageName;

        nodes.add(
          _Node(
            id: '${manifest.packageName}::${decl.className}',
            packageName: manifest.packageName,
            declarationIndex: i,
            decl: decl,
          ),
        );
      }
      modulesByPackage[manifest.packageName] = nodes;
    }

    final allNodes = <String, _Node>{
      for (final nodes in modulesByPackage.values)
        for (final node in nodes) node.id: node,
    };

    final outgoing = <String, Set<String>>{
      for (final id in allNodes.keys) id: <String>{},
    };

    void addEdge(String from, String to) {
      if (from != to) outgoing[from]!.add(to);
    }

    // Rule 2: implicit intra-package sequential edges.
    for (final nodes in modulesByPackage.values) {
      for (var i = 0; i < nodes.length - 1; i++) {
        addEdge(nodes[i].id, nodes[i + 1].id);
      }
    }

    // Rule 1: explicit package-level depends_on edges.
    for (final node in allNodes.values) {
      for (final depPackage in node.decl.dependsOn) {
        final depNodes = modulesByPackage[depPackage];
        if (depNodes == null || depNodes.isEmpty) {
          throw DiModuleUnknownDependencyException(
            packageName: node.packageName,
            className: node.decl.className,
            unknownPackage: depPackage,
          );
        }
        for (final depNode in depNodes) {
          addEdge(depNode.id, node.id);
        }
      }
    }

    int compare(String a, String b) {
      final na = allNodes[a]!;
      final nb = allNodes[b]!;
      final byPackage = na.packageName.compareTo(nb.packageName);
      if (byPackage != 0) return byPackage;
      return na.declarationIndex.compareTo(nb.declarationIndex);
    }

    final resolvedIds = topologicalOrder(
      ids: allNodes.keys,
      edges: outgoing,
      compare: compare,
    );

    final order = resolvedIds
        .map((id) => allNodes[id]!.decl)
        .map(
          (decl) => ResolvedModule(
            packageName: decl.packageName,
            className: decl.className,
            import: decl.import,
            scope: decl.scope,
          ),
        )
        .toList(growable: false);

    return DiModuleResolution(
      order: order,
      beforeModules: order.where((m) => m.scope == ModuleScope.before).toList(),
      afterModules: order.where((m) => m.scope == ModuleScope.after).toList(),
    );
  }
}

/// Internal graph node — a [DiModuleDeclaration] plus the bookkeeping the
/// resolver needs (a globally-unique id and its index within its owning
/// package's declaration list).
class const _Node({
  required final String id,
  required final String packageName,
  required final int declarationIndex,
  required final DiModuleDeclaration decl,
});
