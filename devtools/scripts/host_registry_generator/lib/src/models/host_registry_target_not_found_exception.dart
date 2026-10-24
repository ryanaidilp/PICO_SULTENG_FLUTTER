/// Thrown by `HostRegistryService.generate` (see
/// `../services/host_registry_service.dart`) when the target
/// `injector.dart` path does not exist.
class const HostRegistryTargetNotFoundException(
  /// The path that was expected to exist.
  final String targetPath,
) implements Exception {
  /// Creates a new [HostRegistryTargetNotFoundException] for [targetPath].
  this;

  @override
  String toString() => 'Target injector file not found: $targetPath';
}
