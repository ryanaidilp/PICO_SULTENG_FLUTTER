import 'package:host_registry_generator/src/models/di_resolution_exception.dart';

/// Orders [ids] so every edge `from -> to` in [edges] puts `from` first.
///
/// Deterministic Kahn's algorithm: the "ready" set is resorted with
/// [compare] before each pick, so the result depends only on the graph
/// shape, never on Map/Set iteration order. Shared by `DiModuleResolver`
/// and `TestPrerequisiteResolver`.
///
/// Throws [DiModuleCycleException] naming one concrete cycle when no total
/// order exists.
List<String> topologicalOrder({
  required Iterable<String> ids,
  required Map<String, Set<String>> edges,
  required int Function(String a, String b) compare,
}) {
  final inDegree = <String, int>{for (final id in ids) id: 0};
  for (final targets in edges.values) {
    for (final to in targets) {
      inDegree[to] = inDegree[to]! + 1;
    }
  }

  final remaining = Set<String>.from(inDegree.keys);
  final ready = <String>[
    for (final id in inDegree.keys)
      if (inDegree[id] == 0) id,
  ];

  final resolved = <String>[];
  while (ready.isNotEmpty) {
    ready.sort(compare);
    final next = ready.removeAt(0);
    resolved.add(next);
    remaining.remove(next);

    for (final neighbor in edges[next] ?? const <String>{}) {
      inDegree[neighbor] = inDegree[neighbor]! - 1;
      if (inDegree[neighbor] == 0) ready.add(neighbor);
    }
  }

  if (remaining.isNotEmpty) {
    throw DiModuleCycleException(_findCycle(edges, remaining));
  }
  return resolved;
}

/// Finds one concrete cycle among [remaining] nodes via DFS with a
/// recursion stack, restricted to edges whose target is also in
/// [remaining]. Deterministic: starts the search from the
/// alphabetically-first remaining node.
List<String> _findCycle(
  Map<String, Set<String>> outgoing,
  Set<String> remaining,
) {
  final visited = <String>{};
  final onStack = <String>{};
  final stack = <String>[];
  List<String>? cycle;

  bool visit(String node) {
    visited.add(node);
    onStack.add(node);
    stack.add(node);

    final neighbors = (outgoing[node] ?? const <String>{}).toList()..sort();
    for (final neighbor in neighbors) {
      if (!remaining.contains(neighbor)) continue;

      if (onStack.contains(neighbor)) {
        final idx = stack.indexOf(neighbor);
        cycle = [...stack.sublist(idx), neighbor];
        return true;
      }
      if (!visited.contains(neighbor) && visit(neighbor)) {
        return true;
      }
    }

    stack.removeLast();
    onStack.remove(node);
    return false;
  }

  final sortedRemaining = remaining.toList()..sort();
  for (final id in sortedRemaining) {
    if (!visited.contains(id) && visit(id)) break;
  }

  return cycle ?? sortedRemaining;
}
