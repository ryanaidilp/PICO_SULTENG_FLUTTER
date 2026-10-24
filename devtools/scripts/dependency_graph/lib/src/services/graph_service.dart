import 'package:dependency_graph/src/models/dependency_node.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Service for building and analyzing dependency graphs.
class const GraphService() {
  /// Creates a new [GraphService].
  this;

  /// Analyzes all packages in the workspace and builds a dependency graph.
  DependencyGraph analyze(String workspacePath) {
    final packages = PackageScanner.scan(workspacePath);
    final packageNames = packages.map((p) => p.name).toSet();

    final nodes = <DependencyNode>[];
    final edges = <DependencyEdge>[];

    for (final pkg in packages) {
      final internalDeps = pkg.dependencies
          .where(packageNames.contains)
          .toList();
      final internalDevDeps = pkg.devDependencies
          .where(packageNames.contains)
          .toList();

      final node = DependencyNode(
        name: pkg.name,
        path: pkg.path,
        version: pkg.version,
        dependencies: internalDeps,
        devDependencies: internalDevDeps,
        isFlutter: pkg.isFlutter,
      );

      nodes.add(node);

      for (final dep in internalDeps) {
        edges.add(DependencyEdge(from: pkg.name, to: dep));
      }

      for (final dep in internalDevDeps) {
        edges.add(
          DependencyEdge(from: pkg.name, to: dep, isDevDependency: true),
        );
      }
    }

    return DependencyGraph(nodes: nodes, edges: edges);
  }
}
