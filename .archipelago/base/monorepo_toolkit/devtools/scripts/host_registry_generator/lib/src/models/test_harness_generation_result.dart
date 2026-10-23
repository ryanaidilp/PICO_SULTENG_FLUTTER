import 'package:host_registry_generator/src/models/test_prerequisite_declaration.dart';
import 'package:meta/meta.dart';

/// Summary of a single `HostRegistryService.generateTestHarness` run.
@immutable
class const TestHarnessGenerationResult({
  /// The prerequisites written to the harness, in install order.
  required final List<TestPrerequisiteDeclaration> prerequisites,

  /// Whether [targetPath] was (or, with `write: false`, would be) created or
  /// rewritten.
  required final bool changed,

  /// The `composition_root_harness.dart` path that was (or would have been)
  /// written.
  required final String targetPath,
}) {
  /// Creates a new [TestHarnessGenerationResult].
  this;
}
