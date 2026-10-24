import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:size_analyzer/src/models/size_node.dart';
import 'package:size_analyzer/src/reporters/size_metrics_reporter.dart';

class const SizeAnalyzerService({
  required final String rootPath,
  final SizeMetricsReporter reporter = const NoopSizeMetricsReporter(),
}) {
  /// Parses the JSON tree produced by `flutter build --analyze-size`.
  ///
  /// The JSON has a "root" object with nested "children" arrays.
  /// Each node has "n" (name) and "value" (bytes). We collect the
  /// direct children of the root and aggregate by top-level package name.
  static List<SizeNode> parseJson(String jsonContent) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    final root = data['root'] as Map<String, dynamic>?;
    if (root == null) return [];

    final children = root['children'] as List?;
    if (children == null || children.isEmpty) return [];

    final totals = <String, int>{};
    for (final child in children.whereType<Map<String, dynamic>>()) {
      final name = _nodeName(child);
      final value = (child['value'] as num?)?.toInt() ?? 0;
      totals[name] = (totals[name] ?? 0) + value;
    }

    final nodes =
        totals.entries
            .map((e) => SizeNode(name: e.key, bytes: e.value))
            .toList()
          ..sort((a, b) => b.bytes.compareTo(a.bytes));
    return nodes;
  }

  static String _nodeName(Map<String, dynamic> node) {
    final raw =
        (node['n'] as String?) ?? (node['name'] as String?) ?? 'unknown';
    // Normalise package:foo/bar/baz.dart → package:foo
    if (raw.startsWith('package:')) {
      return raw.split('/').first;
    }
    return raw;
  }

  static List<SizeNodeDiff> diffBaseline({
    required List<SizeNode> current,
    required List<SizeNode> baseline,
  }) {
    final baselineMap = {for (final n in baseline) n.name: n.bytes};
    final diffs = <SizeNodeDiff>[];

    for (final node in current) {
      final baseBytes = baselineMap[node.name] ?? 0;
      final delta = node.bytes - baseBytes;
      if (delta != 0) {
        diffs.add(
          SizeNodeDiff(name: node.name, bytes: node.bytes, delta: delta),
        );
      }
    }

    final currentNames = {for (final node in current) node.name};
    for (final entry in baselineMap.entries) {
      if (!currentNames.contains(entry.key)) {
        diffs.add(SizeNodeDiff(name: entry.key, bytes: 0, delta: -entry.value));
      }
    }

    diffs.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return diffs;
  }

  Future<List<SizeNode>> analyzeJson(
    String jsonPath, {
    String? platform,
  }) async {
    final file = File(jsonPath);
    if (!file.existsSync()) {
      throw FileSystemException('Size analysis JSON not found', jsonPath);
    }
    final nodes = parseJson(file.readAsStringSync());
    if (platform != null) {
      await reporter.report(platform: platform, nodes: nodes, version: null);
    }
    return nodes;
  }

  void updateBaseline(List<SizeNode> nodes, String baselinePath) {
    final file = File(p.join(rootPath, baselinePath));
    file.parent.createSync(recursive: true);
    final data = nodes.map((n) => {'name': n.name, 'bytes': n.bytes}).toList();
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'nodes': data}),
    );
  }

  List<SizeNode> loadBaseline(String baselinePath) {
    final file = File(p.join(rootPath, baselinePath));
    if (!file.existsSync()) return [];
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final nodes = (data['nodes'] as List).cast<Map<String, dynamic>>();
    return nodes
        .map(
          (n) => SizeNode(
            name: n['name'] as String,
            bytes: (n['bytes'] as num).toInt(),
          ),
        )
        .toList();
  }
}
