import 'package:host_registry_generator/src/models/resolved_module.dart';
import 'package:meta/meta.dart';

/// The result of `DiModuleResolver.resolve` (see
/// `../services/di_module_resolver.dart`): a single deterministic
/// registration order for every declared `di_modules` entry across the
/// whole workspace, pre-split by `ModuleScope`.
@immutable
class const DiModuleResolution({
  /// Every resolved module across all packages, in one unified
  /// registration order (both scopes interleaved as resolved).
  required final List<ResolvedModule> order,

  /// The subsequence of [order] with `scope: before`, relative order
  /// preserved. Corresponds to `externalPackageModulesBefore`.
  required final List<ResolvedModule> beforeModules,

  /// The subsequence of [order] with `scope: after`, relative order
  /// preserved. Corresponds to `externalPackageModulesAfter`.
  required final List<ResolvedModule> afterModules,
}) {
  /// Creates a new [DiModuleResolution].
  this;
}
