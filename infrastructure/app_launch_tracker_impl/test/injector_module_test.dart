import 'package:app_launch_tracker_impl/app_launch_tracker_impl.dart';
// `dependencies/di.dart` re-exports `package:injectable`, whose `test`
// environment constant collides with `flutter_test`'s `test()` function.
import 'package:dependencies/di.dart' hide test;
import 'package:flutter_test/flutter_test.dart';

// Regression test for Archipelago-i9rh: `AppLaunchTracker`'s `channel` and
// `monitoring` constructor params are optional-only overrides for tests
// (production resolves `monitoring` lazily via its own `isRegistered` check,
// and self-defaults `channel` internally) and must stay annotated
// `@ignoreParam`. Without that annotation, injectable_generator still emits
// `gh<LaunchTimeTrackerChannel>()`/`gh<AppMonitoring>()` in
// `AppLaunchTrackerImplPackageModule.init` despite neither param being
// `required` — and `LaunchTimeTrackerChannel` has no `@injectable`/
// `@singleton` registration anywhere, so every real app's first GetIt
// resolution of `AppLaunchTracker` threw
// `GetIt: Object/factory with type LaunchTimeTrackerChannel is not
// registered`. `host_app_widget.dart` resolves `AppLaunchTracker`
// unconditionally in `_HostAppWidgetState`'s field initializer, so this
// crashed every generated app on first launch.
//
// This test exercises the real generated `AppLaunchTrackerImplPackageModule`
// (not a hand-registered fake) against an isolated `GetIt` instance —
// deliberately with NO `AppMonitoring` registered — to prove the module is
// fully self-contained and resolves without any other package's DI wiring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt isolatedGetIt;

  setUp(() {
    isolatedGetIt = GetIt.asNewInstance();
  });

  tearDown(() async {
    await isolatedGetIt.reset();
  });

  test('AppLaunchTrackerImplPackageModule registers AppLaunchTracker '
      'resolvably with zero other GetIt registrations required', () async {
    await AppLaunchTrackerImplPackageModule().init(GetItHelper(isolatedGetIt));

    expect(() => isolatedGetIt<AppLaunchTracker>(), returnsNormally);
    expect(() => isolatedGetIt<AppLaunchTracker>().start(), returnsNormally);
  });
}
