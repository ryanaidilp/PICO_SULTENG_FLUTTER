import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Category of a package within the workspace.
enum PackageCategory() {
  /// A shared package (shared/).
  shared,

  /// A utility package (utilities/).
  utility,

  /// An API contract package (*_api in infrastructure/ or features/).
  api,

  /// An implementation package (*_impl in infrastructure/ or features/).
  impl,

  /// A standalone feature package (features/ without _api/_impl suffix).
  feature,

  /// An infrastructure package (infrastructure/ without _api/_impl suffix).
  infrastructure,

  /// An app package (apps/).
  app,

  /// A non-feature package (packages/).
  package,

  /// A devtools package (devtools/).
  devtools,
}

/// Represents a dependency rule violation.
class const Violation({
  /// The package that has the violation.
  required final String package,

  /// The dependency causing the violation.
  required final String dependency,

  /// Short name of the violated rule.
  required final String rule,

  /// Human-readable violation message.
  required final String message,

  /// Whether this edge was detected only via a Dart `import` statement,
  /// with no matching `pubspec.yaml` dependency declaration.
  ///
  /// This workspace uses `resolution: workspace` pub mode, under which a
  /// package can `import` another workspace package's code without
  /// declaring it in `pubspec.yaml` at all — `dart pub get` resolves it
  /// fine regardless. A pubspec-dependency-only check would silently miss
  /// these edges, so [ValidateCommand] also scans actual `import`
  /// directives (see [ImportScanner]) and flags this case specifically,
  /// since it is easy to overlook in review (no pubspec diff to catch it).
  final bool viaImportOnly = false,
}) {
  /// Creates a new [Violation].
  this;

  @override
  String toString() {
    final suffix = viaImportOnly
        ? ' [detected via import statement only — no pubspec.yaml '
              'dependency declared; resolution: workspace allowed it '
              'to compile anyway]'
        : '';
    return '[$rule] $package -> $dependency: $message$suffix';
  }
}

/// Command to validate dependency graph rules from ADR-006.
///
/// Enforces architectural layering constraints:
/// 1. `*_api` packages depend ONLY on shared/ + other *_api + meta
/// 2. `*_impl` packages depend on own *_api + shared/ + infra *_api
/// 3. No sideways deps between *_impl packages
/// 4. shared/ cannot depend on features/ or infrastructure/
/// 5. utilities/ cannot depend on features/ or infrastructure/
/// 6. Dependencies flow DOWN: apps -> features -> infrastructure -> packages -> shared
///
/// These rules are checked against the union of two independent
/// dependency sources per package:
///
/// - **pubspec.yaml-declared dependencies** (as before).
/// - **Actual `import` statements** found in each package's `lib/`
///   source, via [ImportScanner].
///
/// The second source exists because this workspace uses
/// `resolution: workspace` pub mode: any package can `import` any other
/// workspace package's public API without declaring it as a
/// `pubspec.yaml` dependency at all, and `dart pub get`/`dart pub
/// upgrade` will resolve it successfully regardless. A pubspec-only check
/// is therefore not a sufficient boundary check — it is a strict subset
/// of what `import`-level scanning can catch. Violations detected only
/// via an import (no matching pubspec.yaml dependency) are flagged with
/// [Violation.viaImportOnly] so they stand out in output.
///
/// This is also the CI-reliable enforcement mechanism for these three
/// rules: the sibling `utilities/app_lints` analyzer plugin implements
/// the same three rules for real-time IDE feedback, but plugin loading
/// under the one-shot `dart analyze` CLI is asynchronous and not awaited
/// by the CLI before it prints results and exits (see
/// https://github.com/dart-lang/sdk/issues/38407) — small/fast `dart
/// analyze` invocations can finish before the plugin isolate has spun up,
/// silently omitting its diagnostics. `graph validate` has no such race:
/// it runs synchronously in this process and is the mechanism CI actually
/// depends on for these rules (see `.github/workflows/ci.yml`).
class ValidateCommand() extends Command<int> {
  /// Creates a new [ValidateCommand].
  this {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output including passing checks.',
    );
  }

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validate dependency graph rules (ADR-006 enforcement).';

  @override
  Future<int> run() async {
    final verbose = argResults!['verbose'] as bool;
    final logger = CliLogger(verbose: verbose);

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final packages = PackageScanner.scan(rootPath);
      final packageNames = packages.map((p) => p.name).toSet();

      logger.info(
        'Validating dependency rules for ${packages.length} '
        'packages...',
      );

      final categories = <String, PackageCategory>{};
      final packagePaths = <String, String>{};

      for (final pkg in packages) {
        final category = _categorize(pkg);
        categories[pkg.name] = category;
        packagePaths[pkg.name] = pkg.path;
      }

      if (verbose) {
        _logCategories(logger, categories);
      }

      final violations = <Violation>[];
      var importOnlyEdgeCount = 0;

      for (final pkg in packages) {
        final category = categories[pkg.name]!;

        // pubspec.yaml-declared internal workspace dependencies. (A
        // package can never declare itself as its own pubspec
        // dependency, so no explicit self-filter is needed here.)
        final pubspecDeps = pkg.dependencies
            .where(packageNames.contains)
            .toSet();

        // Actual `import` statements in lib/, which can reference a
        // workspace package that was never declared in pubspec.yaml at
        // all (see [ImportScanner] docs) — `resolution: workspace` lets
        // this compile fine, so pubspec-only scanning is not a strictly
        // sufficient boundary check on its own. Unlike pubspec deps,
        // imports of a package's own barrel file (`import
        // 'package:self_name/self_name.dart';`, a common internal
        // re-export pattern) DO show up here, so self-references must be
        // filtered explicitly or every self-importing package would be
        // flagged as depending on itself.
        final importDeps = ImportScanner.scanPackageImportNames(pkg.path)
            .where(packageNames.contains)
            .where((dep) => dep != pkg.name)
            .toSet();

        final importOnlyDeps = importDeps.difference(pubspecDeps);
        importOnlyEdgeCount += importOnlyDeps.length;

        final allDeps = {...pubspecDeps, ...importDeps}.toList();

        violations.addAll(
          _validatePackage(
            pkg.name,
            category,
            allDeps,
            categories,
            packagePaths,
            importOnlyDeps,
          ),
        );
      }

      if (verbose) {
        logger.verbose_(
          'Import-only edges scanned (no pubspec.yaml dependency): '
          '$importOnlyEdgeCount',
        );
      }

      if (violations.isEmpty) {
        logger.success(
          'All dependency rules pass! '
          '(${packages.length} packages checked)',
        );
        return 0;
      }

      logger.error('Found ${violations.length} dependency rule violation(s):');
      logger.info('');

      for (final v in violations) {
        logger.warning('  $v');
      }

      logger.info('');
      logger.error(
        'Fix the violations above to comply with ADR-006 '
        'dependency rules.',
      );

      return 1;
    } on Exception catch (e) {
      logger.error('Failed to validate dependencies: $e');
      return 1;
    }
  }

  /// Categorizes a package based on its path and name.
  PackageCategory _categorize(PackageInfo pkg) {
    final path = pkg.path;

    if (path.contains('/apps/')) return PackageCategory.app;
    if (path.contains('/devtools/')) return PackageCategory.devtools;
    if (path.contains('/shared/')) return PackageCategory.shared;
    if (path.contains('/utilities/')) return PackageCategory.utility;
    if (path.contains('/packages/')) return PackageCategory.package;

    if (path.contains('/infrastructure/') || path.contains('/features/')) {
      if (pkg.name.endsWith('_api')) return PackageCategory.api;
      if (pkg.name.endsWith('_impl')) return PackageCategory.impl;

      // Standalone feature or infrastructure package (e.g., introduction).
      if (path.contains('/features/')) return PackageCategory.feature;
      return PackageCategory.infrastructure;
    }

    return PackageCategory.devtools;
  }

  /// Validates a single package's dependencies against the rules.
  ///
  /// [dependencies] is the union of pubspec.yaml-declared dependencies and
  /// dependencies detected via actual `import` statements. [importOnlyDeps]
  /// is the subset detected only via imports (no pubspec.yaml declaration),
  /// used to annotate violations that a pubspec-only check would miss.
  List<Violation> _validatePackage(
    String packageName,
    PackageCategory category,
    List<String> dependencies,
    Map<String, PackageCategory> categories,
    Map<String, String> packagePaths,
    Set<String> importOnlyDeps,
  ) {
    final violations = <Violation>[];

    for (final dep in dependencies) {
      final depCategory = categories[dep];
      if (depCategory == null) continue;

      final depPath = packagePaths[dep] ?? '';
      final viaImportOnly = importOnlyDeps.contains(dep);

      switch (category) {
        case PackageCategory.api:
          violations.addAll(
            _validateApiDep(packageName, dep, depCategory, viaImportOnly),
          );

        case PackageCategory.impl:
          violations.addAll(
            _validateImplDep(
              packageName,
              dep,
              depCategory,
              categories,
              packagePaths,
              viaImportOnly,
            ),
          );

        case PackageCategory.feature:
          // Standalone features follow impl-like rules.
          violations.addAll(
            _validateImplDep(
              packageName,
              dep,
              depCategory,
              categories,
              packagePaths,
              viaImportOnly,
            ),
          );

        case PackageCategory.shared:
          violations.addAll(
            _validateSharedDep(
              packageName,
              dep,
              depCategory,
              depPath,
              viaImportOnly,
            ),
          );

        case PackageCategory.utility:
          violations.addAll(
            _validateUtilityDep(
              packageName,
              dep,
              depCategory,
              depPath,
              viaImportOnly,
            ),
          );

        case PackageCategory.app:
          // Apps can depend on anything except devtools.
          if (depCategory == PackageCategory.devtools) {
            violations.add(
              Violation(
                package: packageName,
                dependency: dep,
                rule: 'no-devtools-dep',
                message: 'App packages should not depend on devtools packages.',
                viaImportOnly: viaImportOnly,
              ),
            );
          }

        case PackageCategory.package:
          // Non-feature packages can depend on shared/ and utilities/.
          if (depCategory == PackageCategory.impl ||
              depCategory == PackageCategory.feature) {
            violations.add(
              Violation(
                package: packageName,
                dependency: dep,
                rule: 'no-upward-dep',
                message:
                    'packages/ cannot depend on feature impl packages. '
                    'Use *_api packages instead.',
                viaImportOnly: viaImportOnly,
              ),
            );
          }
          if (depCategory == PackageCategory.app) {
            violations.add(
              Violation(
                package: packageName,
                dependency: dep,
                rule: 'no-upward-dep',
                message: 'packages/ cannot depend on app packages.',
                viaImportOnly: viaImportOnly,
              ),
            );
          }

        case PackageCategory.infrastructure:
        case PackageCategory.devtools:
          // No specific rules for these beyond general layering.
          break;
      }
    }

    return violations;
  }

  /// Rule 1: *_api packages depend ONLY on shared/ + other *_api + meta.
  List<Violation> _validateApiDep(
    String packageName,
    String dep,
    PackageCategory depCategory,
    bool viaImportOnly,
  ) {
    const allowed = {
      PackageCategory.shared,
      PackageCategory.api,
      PackageCategory.utility,
    };

    if (!allowed.contains(depCategory)) {
      return [
        Violation(
          package: packageName,
          dependency: dep,
          rule: 'api-restricted-deps',
          message:
              '*_api packages can only depend on shared/, utilities/, '
              'and other *_api packages. '
              'Found dependency on ${depCategory.name} package.',
          viaImportOnly: viaImportOnly,
        ),
      ];
    }

    return [];
  }

  /// Rules 2 & 3: *_impl deps and no sideways impl deps.
  List<Violation> _validateImplDep(
    String packageName,
    String dep,
    PackageCategory depCategory,
    Map<String, PackageCategory> categories,
    Map<String, String> packagePaths,
    bool viaImportOnly,
  ) {
    final violations = <Violation>[];

    // Rule 3: No sideways *_impl dependencies.
    // A single-package feature has no _api/_impl split, so its library is
    // its public surface and there is nothing to bypass.
    if (depCategory == PackageCategory.impl ||
        (depCategory == PackageCategory.feature &&
            !_isSinglePackageFeature(dep, packagePaths))) {
      final pkgPath = packagePaths[packageName] ?? '';
      final depPath = packagePaths[dep] ?? '';

      // Allow impl depending on its own sibling impl
      // (e.g., same feature group) only if it's the same feature.
      final pkgFeature = _extractFeatureGroup(pkgPath);
      final depFeature = _extractFeatureGroup(depPath);

      if (pkgFeature != depFeature || pkgFeature == null) {
        violations.add(
          Violation(
            package: packageName,
            dependency: dep,
            rule: 'no-impl-cross-dep',
            message:
                'Impl packages cannot depend on other impl/feature '
                'packages. Use *_api packages for cross-feature '
                'communication.',
            viaImportOnly: viaImportOnly,
          ),
        );
      }
    }

    // Rule: Impl cannot depend on app packages.
    if (depCategory == PackageCategory.app) {
      violations.add(
        Violation(
          package: packageName,
          dependency: dep,
          rule: 'no-upward-dep',
          message:
              'Impl packages cannot depend on app packages. '
              'Dependencies flow downward only.',
          viaImportOnly: viaImportOnly,
        ),
      );
    }

    return violations;
  }

  /// Rule 4: shared/ cannot depend on features/ or infrastructure/.
  List<Violation> _validateSharedDep(
    String packageName,
    String dep,
    PackageCategory depCategory,
    String depPath,
    bool viaImportOnly,
  ) {
    const forbidden = {
      PackageCategory.api,
      PackageCategory.impl,
      PackageCategory.feature,
      PackageCategory.infrastructure,
      PackageCategory.app,
      PackageCategory.package,
    };

    if (forbidden.contains(depCategory)) {
      return [
        Violation(
          package: packageName,
          dependency: dep,
          rule: 'shared-no-upward-dep',
          message:
              'shared/ packages cannot depend on features/, '
              'infrastructure/, packages/, or app packages. '
              'Found dependency on ${depCategory.name} package.',
          viaImportOnly: viaImportOnly,
        ),
      ];
    }

    return [];
  }

  /// Rule 5: utilities/ cannot depend on features/ or infrastructure/.
  List<Violation> _validateUtilityDep(
    String packageName,
    String dep,
    PackageCategory depCategory,
    String depPath,
    bool viaImportOnly,
  ) {
    const forbidden = {
      PackageCategory.api,
      PackageCategory.impl,
      PackageCategory.feature,
      PackageCategory.infrastructure,
      PackageCategory.app,
      PackageCategory.package,
    };

    if (forbidden.contains(depCategory)) {
      return [
        Violation(
          package: packageName,
          dependency: dep,
          rule: 'utility-no-upward-dep',
          message:
              'utilities/ packages cannot depend on features/, '
              'infrastructure/, packages/, or app packages. '
              'Found dependency on ${depCategory.name} package.',
          viaImportOnly: viaImportOnly,
        ),
      ];
    }

    return [];
  }

  /// Extracts the feature group name from a package path.
  ///
  /// For `features/auth/auth_impl` returns `auth`.
  /// For `infrastructure/monitoring_impl` returns `monitoring`.
  /// Returns `null` if the path doesn't match a feature/infra pattern.
  /// The only package in its `features/<name>/` directory.
  bool _isSinglePackageFeature(String dep, Map<String, String> packagePaths) {
    final path = packagePaths[dep] ?? '';
    if (!RegExp(r'/features/[^/]+$').hasMatch(path)) return false;
    return !packagePaths.values.any((other) => other.startsWith('$path/'));
  }

  String? _extractFeatureGroup(String path) {
    // features/auth/auth_api -> auth
    final featureMatch = RegExp('features/([^/]+)/').firstMatch(path);
    if (featureMatch != null) return featureMatch.group(1);

    // infrastructure/monitoring_impl -> monitoring
    // Extract base name by removing _impl/_api suffix.
    final infraMatch = RegExp(r'infrastructure/([^/]+)$').firstMatch(path);
    if (infraMatch != null) {
      final dirName = infraMatch.group(1)!;
      return dirName
          .replaceAll(RegExp(r'_impl$'), '')
          .replaceAll(RegExp(r'_api$'), '')
          .replaceAll(RegExp(r'_noop$'), '');
    }

    return null;
  }

  void _logCategories(
    CliLogger logger,
    Map<String, PackageCategory> categories,
  ) {
    logger.verbose_('');
    logger.verbose_('Package categories:');
    final sorted = categories.entries.toList()
      ..sort((a, b) => a.value.name.compareTo(b.value.name));
    for (final entry in sorted) {
      logger.verbose_('  ${entry.key}: ${entry.value.name}');
    }
    logger.verbose_('');
  }
}
