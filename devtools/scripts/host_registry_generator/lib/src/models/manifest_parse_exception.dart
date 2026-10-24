/// Thrown when a package's `archipelago:` manifest block in `pubspec.yaml`
/// is malformed (missing required fields, wrong types, invalid `scope`).
class const ManifestParseException(
  /// The package whose `pubspec.yaml` failed to parse.
  final String packageName,

  /// A human-readable description of what was wrong.
  final String message,
) implements Exception {
  /// Creates a new [ManifestParseException].
  this;

  @override
  String toString() =>
      'Invalid archipelago manifest in "$packageName": $message';
}
