import 'package:host_registry_generator/src/models/module_scope.dart';
import 'package:meta/meta.dart';

/// One entry in a package's `archipelago.di_modules` list — a single
/// `ExternalModule`-eligible DI module class that package wants registered
/// in the host app's `injector.dart`.
///
/// Parsed from:
/// ```yaml
/// archipelago:
///   di_modules:
///     - class: AppUtilitiesPackageModule
///       import: package:app_utilities/app_utilities.dart # optional
///       depends_on: []                                    # optional
///       scope: before                                      # optional
/// ```
@immutable
class const DiModuleDeclaration._({
  /// The `ExternalModule` class name, e.g. `AppUtilitiesPackageModule`.
  required final String className,

  /// The name of the package that declared this module (from that
  /// package's own `pubspec.yaml` `name:` field) — the owner used for the
  /// resolver's package-level `depends_on` edges and tiebreak sort.
  required final String packageName,

  /// The import URI this class is resolvable from, e.g.
  /// `package:app_utilities/app_utilities.dart`.
  required final String import,

  /// Names of packages (not class names) that must have all of their own
  /// declared `di_modules` registered before this one.
  required final List<String> dependsOn,

  /// Which `InjectableInit` list this module belongs in.
  required final ModuleScope scope,
}) {
  /// Creates a new [DiModuleDeclaration].
  ///
  /// [import] defaults to this repo's universal barrel-file convention —
  /// `package:<packageName>/<packageName>.dart` — when omitted.
  factory({
    required String className,
    required String packageName,
    String? import,
    List<String> dependsOn = const [],
    ModuleScope scope = ModuleScope.before,
  }) => DiModuleDeclaration._(
    className: className,
    packageName: packageName,
    import: import ?? 'package:$packageName/$packageName.dart',
    dependsOn: dependsOn,
    scope: scope,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiModuleDeclaration &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          packageName == other.packageName &&
          import == other.import &&
          scope == other.scope &&
          _listEquals(dependsOn, other.dependsOn);

  @override
  int get hashCode => Object.hash(
    className,
    packageName,
    import,
    scope,
    Object.hashAll(dependsOn),
  );

  @override
  String toString() =>
      'DiModuleDeclaration($packageName::$className, scope: ${scope.name}, '
      'dependsOn: $dependsOn)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
