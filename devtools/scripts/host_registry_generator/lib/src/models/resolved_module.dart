import 'package:host_registry_generator/src/models/module_scope.dart';
import 'package:meta/meta.dart';

/// A `DiModuleDeclaration` (see `di_module_declaration.dart`) placed at a
/// specific position in the `DiModuleResolver`'s (see
/// `di_module_resolver.dart`) resolved registration order.
@immutable
class const ResolvedModule({
  /// The package that declared this module.
  required final String packageName,

  /// The `ExternalModule` class name.
  required final String className,

  /// The import URI this class is resolvable from.
  required final String import,

  /// Which `InjectableInit` list this module belongs in.
  required final ModuleScope scope,
}) {
  /// Creates a new [ResolvedModule].
  this;

  /// A stable, human-readable identifier used in resolver diagnostics
  /// (e.g. cycle error messages): `<packageName>::<className>`.
  String get id => '$packageName::$className';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedModule &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          className == other.className &&
          import == other.import &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(packageName, className, import, scope);

  @override
  String toString() => 'ResolvedModule($id, scope: ${scope.name})';
}
