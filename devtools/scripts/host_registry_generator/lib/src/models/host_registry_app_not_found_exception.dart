/// Thrown by `HostRegistryService.generate` (see
/// `../services/host_registry_service.dart`) when the target app package —
/// derived from `<targetInjectorPath>/../../../pubspec.yaml` — cannot be
/// found among the packages `PackageScanner` discovers in the workspace.
///
/// Without this package, the dependency-closure scope (see
/// `HostRegistryService.dependencyClosure`) cannot be computed, so
/// generation refuses to fall back to an unscoped, whole-workspace scan.
class const HostRegistryAppNotFoundException(
  /// The app directory whose `pubspec.yaml` could not be resolved to a
  /// scanned workspace package.
  final String appDir,
) implements Exception {
  /// Creates a new [HostRegistryAppNotFoundException] for [appDir].
  this;

  @override
  String toString() =>
      'Could not find a workspace package for app directory "$appDir" '
      '(expected a pubspec.yaml there). Cannot compute its dependency '
      'closure.';
}
