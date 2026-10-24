import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/feature_files.dart';

// Keeps cross-feature navigation going through `_api` ports.
//
// Nothing else stops a feature from adding another feature's `_impl` package
// to its pubspec and building that feature's routes directly. A feature
// package may depend on:
//   - another package in its own feature directory (auth_impl -> auth_api)
//   - any other feature's `_api` package
//   - a single-package feature (mini_app_partner -> webview_advanced)
//   - anything outside `features/`
//
// A single-package feature is the only package in its `features/<name>/`
// directory, with no `_impl` or `_noop` suffix. It has no `_api` / `_impl`
// split and no build_prepare twin (CLAUDE.md "Single package"), so its
// library is its public surface and there is no implementation to bypass.
// Split features and impl/noop pairs always have nested packages, so they
// stay guarded.

/// Cross-feature implementation dependencies allowed anyway, keyed by the
/// depending package. Keep it empty: split an `_api` package instead.
const _knownExceptions = <String, Set<String>>{};

({String name, String group, bool atGroupRoot, Set<String> dependencies})
_readPackage(File pub) {
  final text = pub.readAsStringSync();
  final name = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(text)!.group(1)!;
  // Only `dependencies:`: a dev dependency does not ship in the binary.
  final mainBlock = text.split(RegExp('^dev_dependencies:', multiLine: true));
  final dependencies = RegExp(
    '^  ([a-z0-9_]+):',
    multiLine: true,
  ).allMatches(mainBlock.first).map((match) => match.group(1)!).toSet();
  // `features/<group>/<package>/pubspec.yaml`, or `features/<group>/...` for
  // a single-package feature.
  final segments = pub.parent.uri.pathSegments
      .where((s) => s.isNotEmpty)
      .toList();
  final group = segments[segments.lastIndexOf('features') + 1];
  return (
    name: name,
    group: group,
    atGroupRoot: segments.last == group,
    dependencies: dependencies,
  );
}

void main() {
  test("no feature depends on another feature's implementation package", () {
    final packages = featureFiles('/pubspec.yaml').map(_readPackage).toList();
    final groupOf = {
      for (final package in packages) package.name: package.group,
    };
    final groupSize = <String, int>{};
    for (final package in packages) {
      groupSize.update(package.group, (n) => n + 1, ifAbsent: () => 1);
    }
    final singlePackageFeatures = {
      for (final package in packages)
        if (package.atGroupRoot &&
            groupSize[package.group] == 1 &&
            !RegExp(r'_(impl|noop)$').hasMatch(package.name))
          package.name,
    };

    final violations = <String>[];
    for (final package in packages) {
      final allowed = _knownExceptions[package.name] ?? const <String>{};
      for (final dependency in package.dependencies) {
        final dependencyGroup = groupOf[dependency];
        if (dependencyGroup == null) continue;
        if (dependencyGroup == package.group) continue;
        if (dependency.endsWith('_api')) continue;
        if (singlePackageFeatures.contains(dependency)) continue;
        if (allowed.contains(dependency)) continue;
        violations.add('${package.name} -> $dependency');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          "Depend on the owning feature's `_api` package and navigate "
          'through its SDK port. If the target has an implementation but no '
          '`_api` package, split one out rather than adding to '
          '_knownExceptions.',
    );
  });
}
