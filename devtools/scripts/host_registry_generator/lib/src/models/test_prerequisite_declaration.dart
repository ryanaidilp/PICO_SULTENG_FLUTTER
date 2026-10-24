import 'package:meta/meta.dart';

/// One entry in a package's `archipelago.test_prerequisites` list — a
/// single `TestPrerequisite` implementation that package wants installed
/// before its own DI-init-time platform I/O can run under `flutter test`.
///
/// Parsed from:
/// ```yaml
/// archipelago:
///   test_prerequisites:
///     - class: AppDebuggerTestPrerequisite
///       import: package:app_debugger/testing.dart # optional
///       reason: >-
///         AppDebuggerRegisterModule's @preResolve cubits call
///         path_provider getTemporaryDirectory() during $initGetIt.
///       depends_on: []                              # optional
/// ```
@immutable
class const TestPrerequisiteDeclaration._({
  /// The `TestPrerequisite` implementation class name, e.g.
  /// `AppDebuggerTestPrerequisite`.
  required final String className,

  /// The name of the package that declared this prerequisite (from that
  /// package's own `pubspec.yaml` `name:` field) — the owner used for the
  /// resolver's package-level `depends_on` edges and tiebreak sort.
  required final String packageName,

  /// The import URI this class is resolvable from, e.g.
  /// `package:app_debugger/testing.dart`.
  required final String import,

  /// Human-readable "why" this prerequisite exists. Required and
  /// non-empty — emitted verbatim as a `///` comment above the generated
  /// harness entry so the harness explains itself instead of requiring a
  /// future engineer to re-derive the reason from a stack trace.
  required final String reason,

  /// Names of packages (not class names) whose own declared
  /// `test_prerequisites` must install before this one.
  required final List<String> dependsOn,
}) {
  /// Creates a new [TestPrerequisiteDeclaration].
  ///
  /// [import] defaults to this repo's universal test-support barrel
  /// convention — `package:<packageName>/testing.dart` — when omitted.
  factory({
    required String className,
    required String packageName,
    required String reason,
    String? import,
    List<String> dependsOn = const [],
  }) => TestPrerequisiteDeclaration._(
    className: className,
    packageName: packageName,
    import: import ?? 'package:$packageName/testing.dart',
    reason: reason,
    dependsOn: dependsOn,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPrerequisiteDeclaration &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          packageName == other.packageName &&
          import == other.import &&
          reason == other.reason &&
          _listEquals(dependsOn, other.dependsOn);

  @override
  int get hashCode => Object.hash(
    className,
    packageName,
    import,
    reason,
    Object.hashAll(dependsOn),
  );

  @override
  String toString() =>
      'TestPrerequisiteDeclaration($packageName::$className, '
      'dependsOn: $dependsOn)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
