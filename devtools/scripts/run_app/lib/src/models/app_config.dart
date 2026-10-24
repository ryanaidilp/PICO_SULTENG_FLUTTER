/// Configuration for a Flutter app entry in `flavors.yaml`.
class const AppConfig({
  /// The app directory name (e.g. `pico`).
  required final String name,

  /// The list of flavors defined for this app (e.g. `development`, `staging`).
  required final List<String> flavors,
}) {
  /// Creates a new [AppConfig].
  this;

  @override
  String toString() => '$name (${flavors.join(', ')})';
}
