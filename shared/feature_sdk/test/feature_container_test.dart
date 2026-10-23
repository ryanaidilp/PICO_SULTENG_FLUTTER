import 'dart:async';

import 'package:dependencies/di.dart' show GetIt;
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

class _Network();

class _Repo(final _Network network) {
  int closed = 0;

  void close() => closed++;
}

class _Foo();

void main() {
  late GetIt root;

  setUp(() => root = GetIt.asNewInstance()..registerSingleton(_Network()));
  tearDown(() => root.reset());

  /// The shape a feature module uses: import a global, register locals.
  FeatureContainer container({
    void Function(GetIt child)? onBuild,
    Future<void>? buildGate,
  }) => FeatureContainer(
    'auth',
    root: root,
    build: (child, root) async {
      onBuild?.call(child);
      if (buildGate != null) await buildGate;
      child
        ..registerFactory<_Network>(() => root<_Network>())
        ..registerLazySingleton(
          () => _Repo(child<_Network>()),
          dispose: (repo) => repo.close(),
        );
    },
  );

  test('builds lazily on the first acquire, once for all leases', () async {
    var builds = 0;
    final c = container(onBuild: (_) => builds++);
    expect(builds, 0);
    expect(c.debugSnapshot().built, isFalse);

    final a = c.acquire();
    final b = c.acquire();
    await Future.wait([a.ready, b.ready]);

    expect(builds, 1);
    expect(identical(a.get<_Repo>(), b.get<_Repo>()), isTrue);
    expect(c.debugSnapshot(), (
      name: 'auth',
      leases: 2,
      built: true,
      tearingDown: false,
    ));
  });

  test('child resolves imported globals, not anything else', () async {
    final lease = container().acquire();
    await lease.ready;

    expect(identical(lease.get<_Network>(), root<_Network>()), isTrue);
    expect(identical(lease.get<_Repo>().network, root<_Network>()), isTrue);
    root.registerSingleton(_Foo());
    expect(lease.get<_Foo>, throwsStateError);
    expect(root.isRegistered<_Repo>(), isFalse);
    await lease.release();
  });

  test('two features that import one root port share its instance', () async {
    FeatureLease importing(String name) => FeatureContainer(
      name,
      root: root,
      build: (child, root) =>
          child.registerFactory<_Network>(() => root<_Network>()),
    ).acquire();
    final alpha = importing('alpha');
    final beta = importing('beta');
    await Future.wait([alpha.ready, beta.ready]);

    expect(identical(alpha.get<_Network>(), beta.get<_Network>()), isTrue);
  });

  test("a feature cannot resolve another feature's types", () async {
    final alpha = FeatureContainer(
      'alpha',
      root: root,
      build: (child, _) => child.registerSingleton<_Foo>(_Foo()),
    ).acquire();
    final beta = FeatureContainer(
      'beta',
      root: root,
      build: (_, _) {},
    ).acquire();
    await Future.wait([alpha.ready, beta.ready]);

    expect(alpha.get<_Foo>(), isA<_Foo>());
    expect(beta.get<_Foo>, throwsStateError);
  });

  test('nested leases keep the child until the last release', () async {
    final c = container();
    final page = c.acquire();
    await page.ready;
    final repo = page.get<_Repo>();
    final sheet = c.acquire();
    await sheet.ready;

    await sheet.release();
    expect(identical(page.get<_Repo>(), repo), isTrue);
    expect(repo.closed, 0);

    await page.release();
    expect(repo.closed, 1);
    expect(c.debugSnapshot().built, isFalse);
  });

  test(
    'same-route replace: new acquire before old release keeps the child',
    () async {
      var builds = 0;
      final c = container(onBuild: (_) => builds++);
      final old = c.acquire();
      await old.ready;
      final repo = old.get<_Repo>();

      // Flutter mounts the new shell before disposing the old one.
      final replacement = c.acquire();
      await old.release();
      await replacement.ready;

      expect(builds, 1);
      expect(identical(replacement.get<_Repo>(), repo), isTrue);
      expect(repo.closed, 0);
      await replacement.release();
    },
  );

  test('dispose callbacks run once, even on a repeated release', () async {
    final lease = container().acquire();
    await lease.ready;
    final repo = lease.get<_Repo>();

    await Future.wait([lease.release(), lease.release()]);
    await lease.release();

    expect(repo.closed, 1);
    expect(lease.get<_Repo>, throwsStateError);
  });

  test('root registrations survive the child teardown', () async {
    var disposed = 0;
    root
      ..unregister<_Network>()
      ..registerSingleton(_Network(), dispose: (_) => disposed++);
    final lease = container().acquire();
    await lease.ready;
    lease.get<_Network>();

    await lease.release();
    expect(disposed, 0);
    expect(root.isRegistered<_Network>(), isTrue);
  });

  test('acquire during a running release waits, then builds fresh', () async {
    final teardownGate = Completer<void>();
    var builds = 0;
    final c = FeatureContainer(
      'auth',
      root: root,
      build: (child, _) {
        builds++;
        child.registerSingleton(_Foo(), dispose: (_) => teardownGate.future);
      },
    );
    final first = c.acquire();
    await first.ready;
    final firstFoo = first.get<_Foo>();

    final releasing = first.release();
    expect(c.debugSnapshot().tearingDown, isTrue);
    final second = c.acquire();
    var secondReady = false;
    unawaited(second.ready.then((_) => secondReady = true));
    await pumpEventQueue();
    expect(secondReady, isFalse, reason: 'must wait for the teardown');
    expect(builds, 1);

    teardownGate.complete();
    await releasing;
    await second.ready;
    expect(builds, 2);
    expect(identical(second.get<_Foo>(), firstFoo), isFalse);
    await second.release();
  });

  test('a release while waiting on a teardown does not rebuild', () async {
    final teardownGate = Completer<void>();
    var builds = 0;
    final c = FeatureContainer(
      'auth',
      root: root,
      build: (child, _) {
        builds++;
        child.registerSingleton(_Foo(), dispose: (_) => teardownGate.future);
      },
    );
    final first = c.acquire();
    await first.ready;
    final releasing = first.release();

    final quick = c.acquire();
    final quickRelease = quick.release();
    teardownGate.complete();
    await Future.wait([releasing, quickRelease, quick.ready]);

    expect(builds, 1);
    expect(c.debugSnapshot(), (
      name: 'auth',
      leases: 0,
      built: false,
      tearingDown: false,
    ));
  });

  test(
    'release before ready completes tears the child down after the build',
    () async {
      final gate = Completer<void>();
      late GetIt child;
      final c = container(onBuild: (c) => child = c, buildGate: gate.future);
      final lease = c.acquire();

      final released = lease.release();
      gate.complete();
      await Future.wait([released, lease.ready]);

      expect(child.isRegistered<_Repo>(), isFalse, reason: 'child was reset');
      expect(lease.get<_Repo>, throwsStateError);
      expect(c.debugSnapshot().built, isFalse);
    },
  );

  test(
    'a failing build throws to ready, cleans up, and the next acquire retries',
    () async {
      var fail = true;
      var disposed = 0;
      final c = FeatureContainer(
        'auth',
        root: root,
        build: (child, _) async {
          child.registerSingleton(_Foo(), dispose: (_) => disposed++);
          await Future<void>.delayed(Duration.zero);
          if (fail) throw StateError('boom');
        },
      );

      final a = c.acquire();
      final b = c.acquire();
      await expectLater(a.ready, throwsStateError);
      await expectLater(b.ready, throwsStateError);
      expect(disposed, 1, reason: 'partial registrations are disposed');
      expect(c.debugSnapshot().built, isFalse);

      fail = false;
      final retry = c.acquire();
      await retry.ready;
      expect(retry.get<_Foo>(), isA<_Foo>());

      // Failed leases still release cleanly and do not drop the live child.
      await a.release();
      await b.release();
      expect(c.debugSnapshot().built, isTrue);
      await retry.release();
      expect(disposed, 2);
    },
  );

  test('a synchronous build throw also reaches ready', () async {
    final c = FeatureContainer(
      'auth',
      root: root,
      build: (_, _) => throw StateError('sync boom'),
    );
    final lease = c.acquire();
    await expectLater(lease.ready, throwsStateError);
    await lease.release();
    expect(c.debugSnapshot().built, isFalse);
  });

  test(
    'teardown errors reach the releaser, and the next acquire still builds',
    () async {
      var failTeardown = true;
      final c = FeatureContainer(
        'auth',
        root: root,
        build: (child, _) => child.registerSingleton<_Foo>(
          _Foo(),
          dispose: (_) {
            if (failTeardown) throw StateError('teardown');
          },
        ),
      );
      final first = c.acquire();
      await first.ready;

      final releasing = first.release();
      final next = c.acquire();
      await expectLater(releasing, throwsStateError);
      await next.ready;
      expect(next.get<_Foo>(), isA<_Foo>());

      failTeardown = false;
      await next.release();
    },
  );

  test('get before ready throws', () {
    final lease = container(buildGate: Completer<void>().future).acquire();
    expect(lease.get<_Repo>, throwsStateError);
  });
}
