import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:permission_guard/src/models/permission_guard_config.dart';
import 'package:yaml/yaml.dart' show loadYaml;

class const PermissionDiff({
  required final Set<String> added,
  required final Set<String> removed,
});

class const PermissionGuardService({required final String rootPath}) {
  PermissionDiff diff({
    required Set<String> current,
    required Set<String> baseline,
  }) => PermissionDiff(
    added: current.difference(baseline),
    removed: baseline.difference(current),
  );

  Future<void> saveBaseline(List<String> permissions, String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(permissions.join('\n'));
  }

  Future<List<String>> loadBaseline(String path) async {
    final file = File(path);
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    return content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static PermissionGuardConfig loadConfig(String rootPath) {
    final configFile = File(p.join(rootPath, '.permissionguard.yaml'));
    if (!configFile.existsSync()) return const PermissionGuardConfig();
    final yaml = loadYaml(configFile.readAsStringSync()) as Map?;
    if (yaml == null) return const PermissionGuardConfig();
    return PermissionGuardConfig.fromYaml(yaml);
  }
}
