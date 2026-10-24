import 'dart:io';

import 'package:path/path.dart' as path;

/// Utility to find the monorepo root directory.
///
/// Searches upward from a starting directory for a `pubspec.yaml`
/// file that contains a `workspace:` key, indicating it is a Dart
/// workspace root.
class MonorepoFinder() {
  /// Finds the monorepo root by looking for a `pubspec.yaml`
  /// with a `workspace:` key.
  ///
  /// Searches upward from [from] (defaults to the current directory).
  /// Returns `null` if no workspace root is found.
  static String? findRoot({String? from}) {
    var current = from ?? Directory.current.path;

    while (true) {
      final pubspecFile = File(path.join(current, 'pubspec.yaml'));

      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        if (content.contains('workspace:')) {
          return current;
        }
      }

      final parent = path.dirname(current);
      if (parent == current) {
        return null;
      }
      current = parent;
    }
  }

  /// Finds the monorepo root, throwing a [StateError] if not found.
  ///
  /// Searches upward from [from] (defaults to the current directory).
  static String requireRoot({String? from}) {
    final root = findRoot(from: from);
    if (root == null) {
      throw StateError(
        'Could not find monorepo root. '
        'Make sure you are inside a Dart workspace '
        'with a pubspec.yaml containing a workspace: key.',
      );
    }
    return root;
  }
}
