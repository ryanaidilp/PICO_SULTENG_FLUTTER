import 'dart:convert';

/// Represents a node in the dependency graph.
class const DependencyNode({
  /// Package name.
  required final String name,

  /// Absolute path to the package directory.
  required final String path,

  /// Package version.
  final String? version,

  /// Internal dependency names.
  final List<String> dependencies = const [],

  /// Internal dev dependency names.
  final List<String> devDependencies = const [],

  /// Whether this package depends on Flutter SDK.
  final bool isFlutter = false,
}) {
  /// Creates a new [DependencyNode].
  this;

  /// All internal dependencies (both regular and dev).
  List<String> get allDependencies => [...dependencies, ...devDependencies];

  /// Total count of internal dependencies.
  int get dependencyCount => allDependencies.length;

  @override
  String toString() => 'DependencyNode($name)';
}

/// Represents a directed edge in the dependency graph.
class const DependencyEdge({
  /// Package that has the dependency.
  required final String from,

  /// Package being depended on.
  required final String to,

  /// Whether this is a dev dependency.
  final bool isDevDependency = false,
}) {
  /// Creates a new [DependencyEdge].
  this;

  @override
  String toString() => '$from -> $to${isDevDependency ? ' (dev)' : ''}';
}

/// Statistics about the dependency graph.
class const GraphStats({
  /// Total number of packages.
  required final int totalPackages,

  /// Total number of dependency edges.
  required final int totalEdges,

  /// Number of Flutter packages.
  required final int flutterPackages,

  /// Number of Dart-only packages.
  required final int dartPackages,

  /// Number of packages with no dependents.
  required final int rootPackages,

  /// Number of packages with no dependencies.
  required final int leafPackages,

  /// Maximum number of dependencies any single package has.
  required final int maxDependencies,

  /// Average number of dependencies per package.
  required final double avgDependencies,
}) {
  /// Creates a new [GraphStats].
  this;
}

/// The complete dependency graph of a workspace.
class const DependencyGraph({
  /// All packages in the workspace.
  required final List<DependencyNode> nodes,

  /// Directed edges representing dependencies.
  required final List<DependencyEdge> edges,
}) {
  /// Creates a new [DependencyGraph].
  this;

  /// Get a node by name.
  DependencyNode? getNode(String name) {
    for (final node in nodes) {
      if (node.name == name) return node;
    }
    return null;
  }

  /// Get all packages that depend on the given package.
  List<DependencyNode> getDependents(String packageName) {
    final dependents = <DependencyNode>[];
    for (final edge in edges) {
      if (edge.to == packageName) {
        final node = getNode(edge.from);
        if (node != null) dependents.add(node);
      }
    }
    return dependents;
  }

  /// Find packages with no dependents (root packages).
  List<DependencyNode> get rootPackages {
    final dependentNames = edges.map((e) => e.to).toSet();
    return nodes.where((n) => !dependentNames.contains(n.name)).toList();
  }

  /// Find packages with no dependencies (leaf packages).
  List<DependencyNode> get leafPackages =>
      nodes.where((n) => n.dependencyCount == 0).toList();

  /// Detect circular dependencies using Tarjan's algorithm.
  List<List<String>> findCycles() {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>[];

    void dfs(String node, List<String> path) {
      if (recursionStack.contains(node)) {
        final cycleStart = path.indexOf(node);
        if (cycleStart != -1) {
          cycles.add(path.sublist(cycleStart)..add(node));
        }
        return;
      }

      if (visited.contains(node)) return;

      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      for (final edge in edges) {
        if (edge.from == node) {
          dfs(edge.to, List.from(path));
        }
      }

      recursionStack.remove(node);
    }

    for (final node in nodes) {
      if (!visited.contains(node.name)) {
        dfs(node.name, []);
      }
    }

    return cycles;
  }

  /// Get statistics about the graph.
  GraphStats get stats => GraphStats(
    totalPackages: nodes.length,
    totalEdges: edges.length,
    flutterPackages: nodes.where((n) => n.isFlutter).length,
    dartPackages: nodes.where((n) => !n.isFlutter).length,
    rootPackages: rootPackages.length,
    leafPackages: leafPackages.length,
    maxDependencies: nodes.isEmpty
        ? 0
        : nodes.map((n) => n.dependencyCount).reduce((a, b) => a > b ? a : b),
    avgDependencies: nodes.isEmpty
        ? 0
        : nodes.map((n) => n.dependencyCount).reduce((a, b) => a + b) /
              nodes.length,
  );

  /// Format as DOT graph.
  String toDot() {
    final buffer = StringBuffer()
      ..writeln('digraph Dependencies {')
      ..writeln('  rankdir=TB;')
      ..writeln('  node [shape=box, style=filled];')
      ..writeln();

    for (final node in nodes) {
      final color = node.isFlutter ? '#42A5F5' : '#66BB6A';
      final label = node.version != null
          ? '${node.name}\\n${node.version}'
          : node.name;
      buffer.writeln('  "${node.name}" [label="$label", fillcolor="$color"];');
    }

    buffer.writeln();

    for (final edge in edges) {
      final style = edge.isDevDependency ? 'dashed' : 'solid';
      final color = edge.isDevDependency ? '#9E9E9E' : '#424242';
      buffer.writeln(
        '  "${edge.from}" -> "${edge.to}" [style=$style, color="$color"];',
      );
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Format as Mermaid diagram.
  String toMermaid() {
    final buffer = StringBuffer()
      ..writeln('graph TD')
      ..writeln();

    for (final node in nodes) {
      final id = _sanitizeId(node.name);
      final shape = node.isFlutter ? '([${node.name}])' : '[${node.name}]';
      buffer.writeln('  $id$shape');
    }

    buffer.writeln();

    for (final edge in edges) {
      final arrow = edge.isDevDependency ? '-.->' : '-->';
      buffer.writeln(
        '  ${_sanitizeId(edge.from)} $arrow ${_sanitizeId(edge.to)}',
      );
    }

    return buffer.toString();
  }

  /// Format as JSON.
  String toJson() {
    final data = {
      'nodes': nodes
          .map(
            (n) => {
              'name': n.name,
              'path': n.path,
              'version': n.version,
              'dependencies': n.dependencies,
              'devDependencies': n.devDependencies,
              'isFlutter': n.isFlutter,
            },
          )
          .toList(),
      'edges': edges
          .map(
            (e) => {
              'from': e.from,
              'to': e.to,
              'isDevDependency': e.isDevDependency,
            },
          )
          .toList(),
      'stats': {
        'totalPackages': stats.totalPackages,
        'totalEdges': stats.totalEdges,
        'flutterPackages': stats.flutterPackages,
        'dartPackages': stats.dartPackages,
        'rootPackages': stats.rootPackages,
        'leafPackages': stats.leafPackages,
        'maxDependencies': stats.maxDependencies,
        'avgDependencies': stats.avgDependencies,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Format as plain text.
  String toText() {
    final buffer = StringBuffer()
      ..writeln('=== Dependency Graph ===')
      ..writeln()
      ..writeln('Packages (${nodes.length}):');

    final sorted = List<DependencyNode>.from(nodes)
      ..sort((a, b) => b.dependencyCount.compareTo(a.dependencyCount));

    for (final node in sorted) {
      final type = node.isFlutter ? '[Flutter]' : '[Dart]';
      buffer.writeln('  ${node.name} $type');

      if (node.dependencies.isNotEmpty) {
        buffer.writeln('    Dependencies: ${node.dependencies.join(', ')}');
      }
      if (node.devDependencies.isNotEmpty) {
        buffer.writeln('    Dev: ${node.devDependencies.join(', ')}');
      }
    }

    final s = stats;
    buffer
      ..writeln()
      ..writeln('Statistics:')
      ..writeln('  Total packages: ${s.totalPackages}')
      ..writeln('  Total edges: ${s.totalEdges}')
      ..writeln('  Flutter packages: ${s.flutterPackages}')
      ..writeln('  Dart packages: ${s.dartPackages}')
      ..writeln('  Root packages: ${s.rootPackages}')
      ..writeln('  Leaf packages: ${s.leafPackages}')
      ..writeln('  Max dependencies: ${s.maxDependencies}')
      ..writeln('  Avg dependencies: ${s.avgDependencies.toStringAsFixed(2)}');

    final cycles = findCycles();
    if (cycles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('WARNING: Circular dependencies detected:');
      for (final cycle in cycles) {
        buffer.writeln('  ${cycle.join(' -> ')}');
      }
    }

    return buffer.toString();
  }

  static String _sanitizeId(String name) =>
      name.replaceAll('-', '_').replaceAll('.', '_');
}
