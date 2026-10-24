import 'package:meta/meta.dart';

/// Immutable metadata about a package in the workspace.
@immutable
class const PackageInfo({
  /// The package name from `pubspec.yaml`.
  required final String name,

  /// Absolute path to the package directory.
  required final String path,

  /// The package version string.
  required final String version,

  /// Direct dependencies from `pubspec.yaml`.
  required final List<String> dependencies,

  /// Dev dependencies from `pubspec.yaml`.
  required final List<String> devDependencies,

  /// Whether this package depends on the Flutter SDK.
  required final bool isFlutter,

  /// Whether this package has a `test/` directory.
  required final bool hasTests,
}) {
  /// Creates a new [PackageInfo].
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path;

  @override
  int get hashCode => Object.hash(name, path);

  @override
  String toString() => 'PackageInfo($name, path: $path)';
}
