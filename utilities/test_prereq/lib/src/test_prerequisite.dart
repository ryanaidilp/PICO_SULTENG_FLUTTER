/// One package's test-environment prerequisite for `initializeInjector()`.
///
/// Several Archipelago packages perform real platform I/O during DI init --
/// `@preResolve` getters that `injectable` awaits inside `$initGetIt`, or
/// hand-written `MicroPackageModule.init()` bodies that eagerly resolve
/// plugin-backed singletons. Under plain `flutter test` that I/O has no
/// platform channel behind it and throws a `MissingPluginException`.
///
/// A [TestPrerequisite] is the fix the owning package ships: installing a
/// platform-interface fake or a mock initial value so the real call
/// succeeds under test, without changing production behaviour.
///
/// Declared by the owning package in its own `pubspec.yaml` under
/// `archipelago: test_prerequisites:` (see
/// `docs/specs/composition-root-testability/contract-test-prerequisite-manifest.md`),
/// assembled by the generator into the host app's
/// `test/support/composition_root_harness.dart`, and installed via
/// `installCompositionRootPrerequisites()` before `initializeInjector()`
/// runs in a generated `test/di/injector_test.dart`.
///
/// See `docs/adr/017-composition-root-test-prerequisites.md` for the full
/// design rationale.
///
/// ## Invariants
///
/// 1. **Idempotent.** [install] may be called more than once in a single
///    test process (multiple test files, `setUpAll` per group) and must be
///    a no-op on the second and subsequent calls.
/// 2. **No `GetIt` access.** A prerequisite runs *before*
///    `initializeInjector()` and must not read from or write to the
///    container -- otherwise it stops being a prerequisite and becomes a
///    competing composition root.
/// 3. **No `flutter_test` import.** Keeps prerequisites usable from
///    `integration_test/` and from `flutter_test_config.dart` alike, and
///    keeps `flutter_test` out of a shipped package's dependency graph.
/// 4. **Binding-safe.** May assume
///    `TestWidgetsFlutterBinding.ensureInitialized()` has already run (the
///    generated harness guarantees it); must not call it itself.
abstract interface class TestPrerequisite() {
  /// Package that owns this prerequisite, for diagnostics.
  String get owner;

  /// Why it is needed -- mirrors the declaring pubspec's `reason:` field.
  String get reason;

  /// Installs fakes/mock platform instances. Must not throw when already
  /// installed (see invariant 1).
  Future<void> install();

  /// Undoes [install] where the underlying API allows it.
  ///
  /// Most platform-interface fakes have no real teardown path (the fake
  /// simply stays installed for the rest of the process), so the default
  /// shape is a no-op. Implementations that do need to reverse [install]
  /// must override this explicitly: in Dart, a class that `implements`
  /// (rather than `extends`) an interface never inherits a supertype's
  /// method body, so every implementer -- including no-op ones -- provides
  /// its own [uninstall].
  Future<void> uninstall() async {}
}
