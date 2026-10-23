/// Base type for errors raised while resolving `di_modules` declarations
/// into a total registration order.
abstract class const DiResolutionException(
  /// A clear, actionable description of the failure.
  final String message,
) implements Exception {
  @override
  String toString() => message;
}

/// Thrown when `depends_on` edges between declared `di_modules` form a
/// cycle, so no valid total order exists.
///
/// [cycle] names every module id (`<packageName>::<className>`) that
/// participates in the cycle, in order, with the starting id repeated at
/// the end to make the loop explicit (e.g. `A::X -> B::Y -> A::X`).
class DiModuleCycleException(
  /// The module ids forming the cycle (first id repeated at the end).
  final List<String> cycle,
) extends DiResolutionException {
  /// Creates a new [DiModuleCycleException] for the given [cycle].
  this
    : super('Circular di_modules dependency detected: ${cycle.join(' -> ')}');
}

/// Thrown when a `di_modules` entry's `depends_on` names a package that
/// has no `di_modules` of its own declared anywhere in the workspace (so
/// the dependency can never be satisfied).
class DiModuleUnknownDependencyException({
  /// The package that declared the unsatisfiable dependency.
  required final String packageName,

  /// The class whose `depends_on` entry is unsatisfiable.
  required final String className,

  /// The package name referenced in `depends_on` that has no modules.
  required final String unknownPackage,
}) extends DiResolutionException {
  /// Creates a new [DiModuleUnknownDependencyException].
  this
    : super(
        'Package "$packageName" module "$className" declares '
        'depends_on: ["$unknownPackage"], but no package in the workspace '
        'declares any di_modules for "$unknownPackage".',
      );
}

/// Thrown when the same package declares the same `di_modules` class name
/// more than once.
class DiModuleDuplicateException({
  /// The package with the duplicate declaration.
  required final String packageName,

  /// The duplicated class name.
  required final String className,
}) extends DiResolutionException {
  /// Creates a new [DiModuleDuplicateException].
  this
    : super(
        'Package "$packageName" declares di_modules class "$className" '
        'more than once.',
      );
}

/// Thrown when two different packages declare a `di_modules` entry with the
/// same class name — e.g. an impl/noop pair that both still manifest after
/// a `build_prepare` swap. Each `ExternalModule` class must resolve to
/// exactly one package's import; two owners make the reference ambiguous.
class DiModuleCrossPackageDuplicateException({
  /// The duplicated class name.
  required final String className,

  /// The first package encountered declaring [className].
  required final String firstPackageName,

  /// The second package encountered declaring [className].
  required final String secondPackageName,
}) extends DiResolutionException {
  /// Creates a new [DiModuleCrossPackageDuplicateException].
  this
    : super(
        'di_modules class "$className" is declared by both package '
        '"$firstPackageName" and package "$secondPackageName". Each '
        'ExternalModule class name must be unique across the workspace — '
        'check for a stale manifest left behind by a debug/noop swap.',
      );
}
