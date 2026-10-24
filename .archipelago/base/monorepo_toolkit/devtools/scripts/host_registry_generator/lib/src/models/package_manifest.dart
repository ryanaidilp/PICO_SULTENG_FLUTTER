import 'package:host_registry_generator/src/models/di_module_declaration.dart';
import 'package:host_registry_generator/src/models/manifest_parse_exception.dart';
import 'package:host_registry_generator/src/models/module_scope.dart';
import 'package:host_registry_generator/src/models/test_prerequisite_declaration.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// A single workspace package's declared `archipelago:` manifest.
///
/// A package with no `archipelago:` key in its `pubspec.yaml` parses to a
/// [PackageManifest] with an empty [diModules] and empty
/// [testPrerequisites] list — that's the normal case for most workspace
/// packages (leaf packages with no DI aggregation role and no
/// test-environment platform I/O to declare).
@immutable
class const PackageManifest({
  /// The declaring package's name (from its own `pubspec.yaml` `name:`).
  required final String packageName,

  /// This package's declared `archipelago.di_modules` entries, in the
  /// order they appear in `pubspec.yaml`.
  final List<DiModuleDeclaration> diModules = const [],

  /// This package's declared `archipelago.test_prerequisites` entries, in
  /// the order they appear in `pubspec.yaml`.
  final List<TestPrerequisiteDeclaration> testPrerequisites = const [],
}) {
  /// Creates a new [PackageManifest].
  this;

  /// Parses the `archipelago:` block out of a raw `pubspec.yaml` string.
  ///
  /// [packageName] should come from the same source of truth used
  /// elsewhere in the toolkit (`PackageScanner`'s `PackageInfo.name`)
  /// rather than being re-derived from [pubspecContent], so a package
  /// whose directory name and `name:` field disagree is still keyed
  /// consistently across the toolkit.
  ///
  /// Throws [ManifestParseException] if a `di_modules` entry is missing
  /// its required `class` field, declares an unrecognized `scope`, or if a
  /// `test_prerequisites` entry is missing its required `class` or `reason`
  /// field.
  factory parse({required String packageName, required String pubspecContent}) {
    final yaml = loadYaml(pubspecContent);
    if (yaml is! YamlMap) return PackageManifest(packageName: packageName);

    final archipelago = yaml['archipelago'];
    if (archipelago is! YamlMap) {
      return PackageManifest(packageName: packageName);
    }

    final modules = _parseDiModules(
      packageName: packageName,
      archipelago: archipelago,
    );
    final prerequisites = _parseTestPrerequisites(
      packageName: packageName,
      archipelago: archipelago,
    );

    return PackageManifest(
      packageName: packageName,
      diModules: modules,
      testPrerequisites: prerequisites,
    );
  }

  static List<DiModuleDeclaration> _parseDiModules({
    required String packageName,
    required YamlMap archipelago,
  }) {
    final diModulesYaml = archipelago['di_modules'];
    if (diModulesYaml is! YamlList) return const [];

    final modules = <DiModuleDeclaration>[];
    for (final entry in diModulesYaml) {
      if (entry is! YamlMap) {
        throw ManifestParseException(
          packageName,
          'each "di_modules" entry must be a mapping, got: $entry',
        );
      }

      final className = entry['class'];
      if (className is! String || className.isEmpty) {
        throw ManifestParseException(
          packageName,
          'a "di_modules" entry is missing the required "class" field.',
        );
      }

      final importOverride = entry['import'];
      if (importOverride != null && importOverride is! String) {
        throw ManifestParseException(
          packageName,
          '"$className" has a non-string "import" value.',
        );
      }

      final dependsOnYaml = entry['depends_on'];
      final List<String> dependsOn;
      if (dependsOnYaml == null) {
        dependsOn = const [];
      } else if (dependsOnYaml is YamlList) {
        dependsOn = dependsOnYaml.map((e) => e.toString()).toList();
      } else {
        throw ManifestParseException(
          packageName,
          '"$className" has a non-list "depends_on" value.',
        );
      }

      final scopeYaml = entry['scope'];
      if (scopeYaml != null && scopeYaml is! String) {
        throw ManifestParseException(
          packageName,
          '"$className" has a non-string "scope" value.',
        );
      }

      final ModuleScope scope;
      try {
        scope = ModuleScope.parse(scopeYaml as String?);
      } on FormatException catch (e) {
        throw ManifestParseException(packageName, '"$className": ${e.message}');
      }

      modules.add(
        DiModuleDeclaration(
          className: className,
          packageName: packageName,
          import: importOverride as String?,
          dependsOn: dependsOn,
          scope: scope,
        ),
      );
    }

    return modules;
  }

  static List<TestPrerequisiteDeclaration> _parseTestPrerequisites({
    required String packageName,
    required YamlMap archipelago,
  }) {
    final prerequisitesYaml = archipelago['test_prerequisites'];
    if (prerequisitesYaml is! YamlList) return const [];

    final prerequisites = <TestPrerequisiteDeclaration>[];
    for (final entry in prerequisitesYaml) {
      if (entry is! YamlMap) {
        throw ManifestParseException(
          packageName,
          'each "test_prerequisites" entry must be a mapping, got: $entry',
        );
      }

      final className = entry['class'];
      if (className is! String || className.isEmpty) {
        throw ManifestParseException(
          packageName,
          'a "test_prerequisites" entry is missing the required "class" '
          'field.',
        );
      }

      final importOverride = entry['import'];
      if (importOverride != null && importOverride is! String) {
        throw ManifestParseException(
          packageName,
          '"$className" has a non-string "import" value.',
        );
      }

      final reason = entry['reason'];
      if (reason is! String || reason.isEmpty) {
        throw ManifestParseException(
          packageName,
          '"$className" is missing the required "reason" field.',
        );
      }

      final dependsOnYaml = entry['depends_on'];
      final List<String> dependsOn;
      if (dependsOnYaml == null) {
        dependsOn = const [];
      } else if (dependsOnYaml is YamlList) {
        dependsOn = dependsOnYaml.map((e) => e.toString()).toList();
      } else {
        throw ManifestParseException(
          packageName,
          '"$className" has a non-list "depends_on" value.',
        );
      }

      prerequisites.add(
        TestPrerequisiteDeclaration(
          className: className,
          packageName: packageName,
          import: importOverride as String?,
          reason: reason,
          dependsOn: dependsOn,
        ),
      );
    }

    return prerequisites;
  }
}
