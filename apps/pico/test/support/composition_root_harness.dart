// Test prerequisites for the composition root (ADR-017).
//
// `dart run monorepo_toolkit generate test-harness` rewrites both
// `archipelago:test_prerequisite*` marker regions from each installed
// package's `archipelago: test_prerequisites` pubspec declaration. Never edit
// inside them: declare the prerequisite in the package that does the platform
// I/O and re-run the generator. Hand-written imports go above the markers,
// which is why `directives_ordering` is suppressed (and `unnecessary_ignore`
// for when they happen to sort).
// ignore_for_file: directives_ordering, unnecessary_ignore
import 'package:flutter_test/flutter_test.dart';

// archipelago:test_prerequisite_imports:start
import 'package:pico_data_impl/testing.dart';

// archipelago:test_prerequisite_imports:end

/// Installs the platform fakes every installed package needs before
/// `initializeInjector()` can run under `flutter test`, in resolved order.
///
/// Idempotent: safe to call from several test files in one process. Call it
/// from `setUpAll`, before `initializeInjector()`.
Future<void> installCompositionRootPrerequisites() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // archipelago:test_prerequisites:start
  /// PicoDataImplModule's @preResolve getters call shared_preferences and
  /// path_provider (application support directory) during $initGetIt.
  await PicoDataImplTestPrerequisite().install();
  // archipelago:test_prerequisites:end
}
