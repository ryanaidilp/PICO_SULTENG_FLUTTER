import 'dart:io';

import 'package:dependency_manager/src/services/workspace_locator.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const _sections = ['dependencies', 'dev_dependencies'];

/// A workspace package's directly pinned hosted dependencies.
///
/// Only plain `name: constraint` entries count. `path`, `sdk` and `git`
/// entries are not version pins.
class PubspecPins({
  required final String name,
  required final String path,
  required final Map<String, Map<String, String>> pins,
  required final Set<String> declared,
}) {
  /// Creates pins for one package.
  this;

  /// Reads [pubspecPath].
  factory read(String pubspecPath) =>
      PubspecPins.parse(pubspecPath, File(pubspecPath).readAsStringSync());

  /// Parses [content] as the pubspec at [pubspecPath].
  factory parse(String pubspecPath, String content) {
    final yaml = loadYaml(content) as YamlMap?;
    final pins = <String, Map<String, String>>{};
    final declared = <String>{};
    for (final section in _sections) {
      final entries = yaml?[section];
      if (entries is! YamlMap) continue;
      declared.addAll(entries.keys.cast<String>());
      pins[section] = {
        for (final e in entries.entries)
          if (e.value is String) e.key as String: e.value as String,
      };
    }
    return PubspecPins(
      name: (yaml?['name'] as String?) ?? pubspecPath,
      path: pubspecPath,
      pins: pins,
      declared: declared,
    );
  }

  /// Constraint of [package] in any section, or `null`.
  String? pinOf(String package) {
    for (final section in _sections) {
      final c = pins[section]?[package];
      if (c != null) return c;
    }
    return null;
  }

  Iterable<MapEntry<String, String>> get all =>
      pins.values.expand((m) => m.entries);
}

/// A package pinned with more than one constraint: constraint -> pinners.
typedef Drift = Map<String, Map<String, List<String>>>;

/// Third-party packages pinned directly with different constraints.
Drift findDrift(List<PubspecPins> packages) {
  final byPackage = <String, Map<String, List<String>>>{};
  for (final pkg in packages) {
    for (final e in pkg.all) {
      byPackage
          .putIfAbsent(e.key, () => {})
          .putIfAbsent(e.value, () => [])
          .add(pkg.name);
    }
  }
  byPackage.removeWhere((_, constraints) => constraints.length < 2);
  return byPackage;
}

/// Barrel packages (ADR-043): their own hosted deps are what they re-export.
const barrelPackages = ['dependencies', 'dependencies_core'];

/// Packages that depend on a barrel and still pin something it re-exports:
/// package name -> redundant pins.
Map<String, List<String>> findBarrelDuplicates(List<PubspecPins> packages) {
  final exported = <String>{
    for (final p in packages)
      if (barrelPackages.contains(p.name)) ...?p.pins['dependencies']?.keys,
  };
  final out = <String, List<String>>{};
  for (final p in packages) {
    if (barrelPackages.contains(p.name)) continue;
    if (!p.declared.any(barrelPackages.contains)) continue;
    final dup = [
      for (final e in p.all)
        if (exported.contains(e.key)) e.key,
    ]..sort();
    if (dup.isNotEmpty) out[p.name] = dup;
  }
  return out;
}

/// The highest of [constraints] by lower bound, then upper bound.
String highestConstraint(Iterable<String> constraints) {
  (Version, Version) key(String c) {
    final v = VersionConstraint.parse(c);
    if (v is Version) return (v, v);
    if (v is VersionRange) {
      return (v.min ?? Version(0, 0, 0), v.max ?? Version(1 << 30, 0, 0));
    }
    return (Version(0, 0, 0), Version(1 << 30, 0, 0));
  }

  return constraints.reduce((a, b) {
    final ka = key(a);
    final kb = key(b);
    final byMin = kb.$1.compareTo(ka.$1);
    return (byMin != 0 ? byMin : kb.$2.compareTo(ka.$2)) > 0 ? b : a;
  });
}

/// Rewrites every pin of [package] in [content] to [constraint].
///
/// Returns the new content, or `null` when nothing changed.
String? alignPubspec(String content, String package, String constraint) {
  final yaml = loadYaml(content) as YamlMap?;
  final editor = YamlEditor(content);
  var changed = false;
  for (final section in _sections) {
    final entries = yaml?[section];
    if (entries is YamlMap &&
        entries[package] is String &&
        entries[package] != constraint) {
      editor.update([section, package], constraint);
      changed = true;
    }
  }
  return changed ? editor.toString() : null;
}

/// Pins of every member package under [monorepoRoot].
Future<List<PubspecPins>> readWorkspacePins(String monorepoRoot) async => [
  for (final path in await listWorkspacePubspecs(monorepoRoot))
    PubspecPins.read(path),
];
