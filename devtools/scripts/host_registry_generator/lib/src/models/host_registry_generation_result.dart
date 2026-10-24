import 'package:host_registry_generator/src/models/di_module_resolution.dart';
import 'package:meta/meta.dart';

/// Summary of a single `HostRegistryService.generate` run (see
/// `../services/host_registry_service.dart`).
@immutable
class const HostRegistryGenerationResult({
  /// Number of packages in the target app's transitive dependency closure
  /// (see `HostRegistryService.dependencyClosure`) — the packages actually
  /// eligible to contribute a `di_modules` entry, not the whole workspace.
  required final int packagesScanned,

  /// How many of those packages declared at least one `di_modules` entry.
  required final int packagesWithModules,

  /// Total `di_modules` entries declared across all packages.
  required final int totalModulesDeclared,

  /// The resolved, deterministic registration order.
  required final DiModuleResolution resolution,

  /// Whether [targetPath] was actually rewritten (false when the file
  /// already matched the canonical generated form — idempotent re-run).
  required final bool changed,

  /// The `injector.dart` path that was (or would have been) updated.
  required final String targetPath,

  /// Module class names found in the file but declared by no manifest in the
  /// app's closure; kept in place instead of being dropped (see `--prune`).
  final List<String> preservedModules = const [],
}) {
  /// Creates a new [HostRegistryGenerationResult].
  this;
}
